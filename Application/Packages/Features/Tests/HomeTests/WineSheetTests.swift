import Core
import Foundation
import Match
import Testing
@testable import Home

// MARK: Doubles

private actor MapSpy: PalateMapRepository {
    var map: PalateMap?
    private(set) var rated: [(map: PalateMap, wineKey: String, verdict: Verdict)] = []

    init(map: PalateMap?) { self.map = map }

    func currentMap() async throws -> PalateMap? { map }
    func saveQuizMap(_ map: PalateMap, at date: Date) async throws { self.map = map }
    func history() async throws -> [MapChange] { [] }
    func saveRatedMap(_ map: PalateMap, wineKey: String, verdict: Verdict, at date: Date) async throws {
        self.map = map
        rated.append((map, wineKey, verdict))
    }
}

private actor CellarSpy: CellarRepository {
    private(set) var tasted: [String: Verdict] = [:]
    func wineKeys() async throws -> Set<String> { Set(tasted.keys) }
    func addWantToTry(_ wine: Wine) async throws {}
    func tastedWineKeys() async throws -> Set<String> { Set(tasted.keys) }
    func addTasted(_ wine: Wine, verdict: Verdict) async throws { tasted[wine.id] = verdict }
}

@MainActor
private final class HomeLoaderSpy: LoadHomeUseCaseProtocol {
    var calls = 0
    func execute() async throws -> HomeLoadResultModel {
        calls += 1
        return HomeLoadResultModel(model: .full, inviteLink: nil, cellarWineKeys: [])
    }
}

@MainActor
private struct FixedRating: RateWineUseCaseProtocol {
    var changes: [AxisChange]
    func execute(_ wine: Wine, verdict: Verdict, addToCellar: Bool) async throws -> [AxisChange] { changes }
}

@MainActor
private struct FailingRating: RateWineUseCaseProtocol {
    struct Failure: Error {}
    func execute(_ wine: Wine, verdict: Verdict, addToCellar: Bool) async throws -> [AxisChange] { throw Failure() }
}

@MainActor
private struct SavingCellar: AddWineToCellarUseCaseProtocol {
    func execute(_ wine: Wine) async throws {}
}

private func flat(_ value: Double) -> PalateMap {
    PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, value) }))
}

// MARK: HOME-R24 · RateWineUseCase

@MainActor
struct RateWineUseCaseTests {
    let wine = Wine(id: "w1", name: "Fresh", origin: "Douro, Portugal",
                    profile: PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, $0 == .acidity ? 9.0 : 5.0) })))

    @Test func HOME_R24_yes_movesTheMapTowardTheWine_andKeepsItTasted() async throws {
        let maps = MapSpy(map: flat(5))
        let cellar = CellarSpy()
        let useCase = RateWineUseCase(maps: maps, cellar: cellar, now: { Date(timeIntervalSince1970: 0) })

        let changes = try await useCase.execute(wine, verdict: .yes, addToCellar: true)

        let saved = try #require(await maps.rated.first)
        #expect(saved.wineKey == "w1")
        #expect(saved.verdict == .yes)
        #expect(saved.map[.acidity] > 5)
        #expect(await cellar.tasted == ["w1": .yes])
        // Only the axis that moved by the threshold comes back (QUIZ-R23).
        #expect(changes.map(\.axis) == [.acidity])
        #expect(changes.first?.wentUp == true)
    }

    @Test func HOME_R24_notNow_movesTheMap_withoutTheCellar() async throws {
        let maps = MapSpy(map: flat(5))
        let cellar = CellarSpy()
        let useCase = RateWineUseCase(maps: maps, cellar: cellar, now: Date.init)
        _ = try await useCase.execute(wine, verdict: .no, addToCellar: false)
        #expect(await maps.rated.count == 1)
        #expect(await cellar.tasted.isEmpty)
    }

    @Test func withoutAMap_nothingIsSaved() async {
        let maps = MapSpy(map: nil)
        let cellar = CellarSpy()
        let useCase = RateWineUseCase(maps: maps, cellar: cellar, now: Date.init)
        await #expect(throws: RateWineUseCase.RatingError.self) { try await useCase.execute(wine, verdict: .yes, addToCellar: true) }
        #expect(await cellar.tasted.isEmpty)
    }
}

// MARK: HOME-R24, R28 · HomeViewModel

@MainActor
struct HomeRatingViewModelTests {
    private func viewModel(rating: any RateWineUseCaseProtocol, loader: HomeLoaderSpy,
                           noticeDuration: Duration = .seconds(60)) -> HomeViewModel {
        HomeViewModel(loadHomeUseCase: loader, addWineToCellarUseCase: SavingCellar(), rateWineUseCase: rating,
                      coordinator: HomeCoordinator(onOpenCourse: { _ in }, onOpenLearn: { _ in }),
                      now: Date.init, calendar: .current, noticeDuration: noticeDuration)
    }

    @Test func HOME_R24_rating_rebuildsTheHome_andTellsWhichAxesMoved() async throws {
        let loader = HomeLoaderSpy()
        let model = viewModel(rating: FixedRating(changes: [
            AxisChange(axis: .acidity, before: 5, after: 6),
            AxisChange(axis: .oak, before: 5, after: 4.5)
        ]), loader: loader)
        await model.load()
        let wine = try #require(HomeContentModel.full.catalog.first)

        await model.rate(wine, verdict: .yes, addToCellar: false)

        #expect(loader.calls == 2)
        #expect(model.uiModel.notice == "Map updated · Acidity ↑ · Oak ↓")
    }

    @Test func HOME_R24_keptInTheCellar_saysSo() async throws {
        let model = viewModel(rating: FixedRating(changes: [AxisChange(axis: .fruit, before: 5, after: 6)]), loader: HomeLoaderSpy())
        await model.load()
        await model.rate(try #require(HomeContentModel.full.catalog.first), verdict: .yes, addToCellar: true)
        #expect(model.uiModel.notice == "Saved to Cellar · Map updated · Fruit ↑")
    }

    @Test func HOME_R24_aFailedRating_changesNothing() async throws {
        let loader = HomeLoaderSpy()
        let model = viewModel(rating: FailingRating(), loader: loader)
        await model.load()
        await model.rate(try #require(HomeContentModel.full.catalog.first), verdict: .no, addToCellar: true)
        #expect(loader.calls == 1)
        #expect(model.uiModel.notice == nil)
    }

    @Test func HOME_R24_theNoticeGoesAway() async throws {
        let model = viewModel(rating: FixedRating(changes: []), loader: HomeLoaderSpy(), noticeDuration: .milliseconds(10))
        await model.load()
        await model.rate(try #require(HomeContentModel.full.catalog.first), verdict: .maybe, addToCellar: false)
        #expect(model.uiModel.notice == "Map updated · barely moved")
        try await Task.sleep(for: .milliseconds(200))
        #expect(model.uiModel.notice == nil)
    }

    @Test func HOME_R28_saveToCellar_saysSaved() async throws {
        let model = viewModel(rating: FixedRating(changes: []), loader: HomeLoaderSpy())
        await model.load()
        let wine = try #require(HomeContentModel.full.catalog.first)
        await model.addToCellar(wine)
        #expect(model.uiModel.cellarWineKeys.contains(wine.id))
        #expect(model.uiModel.notice == "Saved to Cellar · \(wine.name)")
    }
}

// MARK: WineDetailUIModel · HOME-R28a

struct WineDetailUIModelTests {
    let now = Date(timeIntervalSince1970: 1_793_000_000) // 2026
    private func wine(vintage: Int? = 2023, producer: String = "Soalheiro") -> Wine {
        Wine(id: "w", name: "Alvarinho", producer: producer, vintage: vintage, type: "White",
             origin: "Monção e Melgaço, Portugal", region: "Monção e Melgaço", country: "Portugal",
             grapes: ["Alvarinho"], profile: PalateMap([.acidity: 8, .fruit: 6]),
             note: "Lemon, white peach", serving: 8...10, howToServe: "Cold.", pairings: ["Shellfish", "Grilled fish"])
    }
    private func model(_ wine: Wine, _ source: WineDetailUIModel.Source) -> WineDetailUIModel {
        WineDetailUIModel(wine: wine, source: source, palateMap: flat(5), now: now)
    }

    @Test func HOME_R28a_palateRow_showsTitleAndProducer() {
        let suggestion = PalateWineSuggestion(wine: wine(), axis: .acidity, level: .high)
        let detail = model(suggestion.wine, .palate(suggestion))
        #expect(detail.eyebrow == "Soalheiro")
        #expect(detail.title == "Alvarinho")
        #expect(detail.resultCount == nil)
    }

    @Test func HOME_R28a_theWine_factsInTheDesignOrder() {
        let detail = model(wine(), .discovery(.familiar, index: 0, count: 1))
        let facts = detail.facts
        #expect(facts.map(\.label) == ["Origin", "Vintage", "Serve at", "Style", "Grape & notes"])
        #expect(facts.map(\.value) == ["Monção e Melgaço, Portugal", "2023 · 3 years", "8–10°C", "White",
                                       "Alvarinho · Lemon, white peach"])
        #expect(detail.pairings == "Shellfish, Grilled fish")
        // Vintage beside Origin, Grape & notes beside Style.
        #expect(facts.filter(\.besidePrevious).map(\.label) == ["Vintage", "Grape & notes"])
    }

    @Test func noVintage_readsNonVintage() {
        #expect(model(wine(vintage: nil), .discovery(.familiar, index: 0, count: 1)).vintageLine == "Non-vintage")
    }

    @Test func HOME_R28_result_isYourPick_withItsCount() {
        let detail = model(wine(), .discovery(.familiar, index: 1, count: 4))
        #expect(detail.eyebrow == "Your pick · Soalheiro")
        #expect(detail.resultCount == "2 of 4 white wines for your choices")
        #expect(detail.hasAnotherResult)
        #expect(model(wine(), .discovery(.familiar, index: 0, count: 1)).resultCount == "The only white for your choices")
    }

    @Test func surpriseMe_readsHowFarFromTheMap() {
        let familiar = model(wine(), .discovery(.familiar, index: 0, count: 1))
        let surprise = model(wine(), .discovery(.surprise, index: 0, count: 1))
        let percent = Int(familiar.percentage.dropLast()) ?? 0
        #expect(surprise.percentage == "\(100 - percent)%")
        #expect(surprise.percentageCaption == "away from your map")
    }

    @Test func HOME_R24_afterTheCellarQuestion_aLightLineForEachAnswer() {
        let resources = HomeResourcesUIModel()
        #expect(resources.wineSheetFeedback(verdict: .yes, kept: true) == "Glad you loved it! It's in your cellar now.")
        #expect(resources.wineSheetFeedback(verdict: nil, kept: false) == "No rush. It'll be here when you're ready.")
        let lines = [Verdict.yes, .maybe, .no].flatMap { v in [true, false].map { resources.wineSheetFeedback(verdict: v, kept: $0) } }
            + [true, false].map { resources.wineSheetFeedback(verdict: nil, kept: $0) }
        #expect(Set(lines).count == 8)
    }
}
