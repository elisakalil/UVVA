import Core
import Foundation
import Match
import Testing
@testable import Home

// MARK: Doubles

@MainActor
private final class HomeLoaderSpy: LoadHomeUseCaseProtocol {
    var calls = 0
    func execute() async throws -> HomeLoadResultModel {
        calls += 1
        return HomeLoadResultModel(model: .full, inviteLink: nil)
    }
}

@MainActor
private struct SavingCellar: AddWineToCellarUseCaseProtocol {
    func execute(_ wine: Wine) async throws {}
}

private func flat(_ value: Double) -> PalateMap {
    PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, value) }))
}

// MARK: HOME-R24, R28 · HomeViewModel

@MainActor
struct HomeCellarNoteViewModelTests {
    private func viewModel(loader: HomeLoaderSpy = HomeLoaderSpy(),
                           onOpenCellarNote: @escaping (Wine, Verdict?, Bool) -> Void = { _, _, _ in }) -> HomeViewModel {
        HomeViewModel(loadHomeUseCase: loader, loadPalateStateUseCase: PalateStateStub(), rankWinesUseCase: WineRankingSpy(),
                      addWineToCellarUseCase: SavingCellar(),
                      coordinator: HomeCoordinator(onOpenCourse: { _ in }, onOpenLearn: { _ in },
                                                   onOpenCellarNote: onOpenCellarNote),
                      now: Date.init, calendar: .current, noticeDuration: .seconds(60), curtainDuration: .zero)
    }

    @Test func HOME_R24_addToCellar_opensTheCellarNote_withTheVerdictTheWineHad() async throws {
        var opened: [(String, Verdict?, Bool)] = []
        let model = viewModel(onOpenCellarNote: { opened.append(($0.id, $1, $2)) })
        await model.load()
        let rated = try #require(HomeContentModel.full.catalog.first { $0.id == "pontoforte" })
        let unrated = try #require(HomeContentModel.full.catalog.first { $0.id != "pontoforte" })

        model.openCellarNote(for: rated, fromHero: true)
        model.openCellarNote(for: unrated, fromHero: false)

        // Rated before: the note asks "Rate it again?". Not rated: "Have you had this wine?" (CELLAR-R14a).
        #expect(opened.map(\.0) == ["pontoforte", unrated.id])
        #expect(opened.map(\.1) == [.yes, nil])
        // HOME-R10c: only the Hero's note takes the Home back to its top once saved.
        #expect(opened.map(\.2) == [true, false])
    }

    @Test func HOME_R24_openingTheNote_readsNothing() async throws {
        let loader = HomeLoaderSpy()
        let model = viewModel(loader: loader)
        await model.load()
        model.openCellarNote(for: try #require(HomeContentModel.full.catalog.first), fromHero: false)
        #expect(loader.calls == 1)
        #expect(model.uiModel.notice == nil)
    }

    @Test func HOME_R28_saveToCellar_saysSaved() async throws {
        let model = viewModel()
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
        #expect(facts.map(\.label) == ["Origin", "Vintage", "Style", "Grape & notes"])
        #expect(facts.map(\.value) == ["Monção e Melgaço, Portugal", "2023 · 3 years", "White",
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

    @Test func HOME_R28a_howToServe_startsWithTheTemperature() {
        let detail = model(wine(), .discovery(.familiar, index: 0, count: 1))
        #expect(detail.servingTemperature == "8–10 °C")
        #expect(detail.howToServe == "Cold.")
        #expect(detail.showsServing)
        // The temperature alone is enough for the section; with neither, it is left out.
        var bare = wine()
        bare.howToServe = nil
        #expect(model(bare, .discovery(.familiar, index: 0, count: 1)).showsServing)
        bare.serving = nil
        #expect(!model(bare, .discovery(.familiar, index: 0, count: 1)).showsServing)
    }
}
