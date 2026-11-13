import Core
import Foundation
import Match
import Testing
@testable import Home

// MARK: HOME-R08a · Só vinhos novos

/// A catalog already ranked, with one recipe for reds, that counts how often the recipes are read.
private actor RankedCatalogSpy: CatalogRepository {
    let ranked: [Wine]
    private(set) var recipeReads = 0

    init(_ ranked: [Wine]) { self.ranked = ranked }

    func winesClosest(to map: PalateMap, limit: Int) async throws -> [Wine] { Array(ranked.prefix(limit)) }
    func recipes() async throws -> [Recipe] {
        recipeReads += 1
        return [Recipe(id: "stew", title: "Lamb stew", why: "Reds and lamb.", course: "main", wineTypes: ["Red"],
                       profile: PalateMap([.body: 7]))]
    }
    func glossary() async throws -> [GlossaryTerm] { [] }
    func firstPathModule() async throws -> CourseSummary? { nil }
}

@MainActor
struct RankNewWinesTests {
    private let map = PalateMap([.body: 7])
    /// Ranked: a white no recipe goes with, then three reds.
    private let wines = [
        Wine(id: "white", name: "White", type: "White", origin: "", profile: PalateMap([.body: 7])),
        Wine(id: "red1", name: "Red 1", type: "Red", origin: "", profile: PalateMap([.body: 7])),
        Wine(id: "red2", name: "Red 2", type: "Red", origin: "", profile: PalateMap([.body: 6])),
        Wine(id: "red3", name: "Red 3", type: "Red", origin: "", profile: PalateMap([.body: 5]))
    ]

    @Test func HOME_R08a_theRanking_leavesTheCellarOut_andPairsTheFirstNewWine() async throws {
        let useCase = RankWinesUseCase(catalog: RankedCatalogSpy(wines))
        let ranked = try await useCase.execute(for: map, excluding: ["red1"])
        #expect(ranked.map(\.id) == ["white", "red2", "red3"])
        // The white has no recipe; the first new red takes the dish, and only it.
        #expect(ranked.filter { $0.dish != nil }.map(\.id) == ["red2"])
    }

    @Test func HOME_R08a_aWineToTheCellar_thatWasNotTheHero_leaves_withoutReadingRecipes() async throws {
        let catalog = RankedCatalogSpy(wines)
        let useCase = RankWinesUseCase(catalog: catalog)
        let ranked = try await useCase.execute(for: map, excluding: [])
        let reads = await catalog.recipeReads

        let narrowed = try await useCase.narrow(ranked, excluding: ["red3"], for: map)

        #expect(narrowed.map(\.id) == ["white", "red1", "red2"])
        #expect(narrowed.filter { $0.dish != nil }.map(\.id) == ["red1"])
        #expect(await catalog.recipeReads == reads)
    }

    @Test func HOME_R08a_theHeroToTheCellar_theNextNewWineTakesTheDish() async throws {
        let useCase = RankWinesUseCase(catalog: RankedCatalogSpy(wines))
        let ranked = try await useCase.execute(for: map, excluding: [])

        let narrowed = try await useCase.narrow(ranked, excluding: ["red1"], for: map)

        #expect(narrowed.map(\.id) == ["white", "red2", "red3"])
        #expect(narrowed.filter { $0.dish != nil }.map(\.id) == ["red2"])
    }

    @Test func HOME_R08a_theHero_isNeverAWineInTheCellar() throws {
        var model = HomeContentModel.full
        let hero = try #require(HomeCardsBuilder().topMatch(model))
        // Even a list that still carries its dish: the Hero is not taken from the Cellar.
        model.cellarWineKeys = [hero.id]
        #expect(HomeCardsBuilder().topMatch(model)?.id != hero.id)
    }
}

// MARK: HOME-R08a · A Home quando a Adega muda

@MainActor
private final class LoaderSpy: LoadHomeUseCaseProtocol {
    func execute() async throws -> HomeLoadResultModel { HomeLoadResultModel(model: .full, inviteLink: nil) }
}

@MainActor
private struct NoCellar: AddWineToCellarUseCaseProtocol {
    func execute(_ wine: Wine) async throws {}
}

@MainActor
struct HomeNewWinesRefreshTests {
    let palate = PalateStateStub()
    let ranking = WineRankingSpy()

    private func loadedViewModel() async -> HomeViewModel {
        let model = HomeViewModel(loadHomeUseCase: LoaderSpy(), loadPalateStateUseCase: palate, rankWinesUseCase: ranking,
                                  addWineToCellarUseCase: NoCellar(),
                                  coordinator: HomeCoordinator(onOpenCourse: { _ in }, onOpenLearn: { _ in }),
                                  now: Date.init, calendar: .current, curtainDuration: .zero)
        await model.load()
        return model
    }

    private func hero(_ model: HomeViewModel) -> Wine? {
        guard case let .topMatch(wine) = model.uiModel.content?.cards.first(where: { $0.kind == "topMatch" }) else { return nil }
        return wine
    }

    private func chooseYourself(_ model: HomeViewModel) -> [Wine] {
        guard case let .chooseYourWine(list) = model.uiModel.content?.cards.first(where: { $0.kind == "chooseYourWine" }) else { return [] }
        return list.wines
    }

    @Test func HOME_R08a_theHeroToTheCellar_leavesEveryCard_withoutANewRanking() async throws {
        let model = await loadedViewModel()
        let kept = try #require(hero(model))
        #expect(chooseYourself(model).contains { $0.id == kept.id })

        palate.state.cellarWineKeys = [kept.id]
        await model.refreshMatches()

        #expect(ranking.calls == 0)
        #expect(ranking.narrowCalls == 1)
        let next = try #require(hero(model))
        #expect(next.id != kept.id)
        #expect(!chooseYourself(model).contains { $0.id == kept.id })
    }

    @Test func HOME_R08a_aWineThatLeftTheCellar_isNewAgain() async throws {
        let model = await loadedViewModel()
        let wine = try #require(chooseYourself(model).last)
        palate.state.cellarWineKeys = [wine.id]
        await model.refreshMatches()
        #expect(!chooseYourself(model).contains { $0.id == wine.id })

        // Its note deleted in the Cellar: only a new ranking brings it back.
        palate.state.cellarWineKeys = []
        await model.refreshMatches()

        #expect(ranking.calls == 1)
        #expect(chooseYourself(model).contains { $0.id == wine.id })
    }
}
