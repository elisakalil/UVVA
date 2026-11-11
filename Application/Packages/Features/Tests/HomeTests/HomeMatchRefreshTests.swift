import Combine
import Core
import Foundation
import Match
import Testing
@testable import Home

@MainActor
private final class LoaderSpy: LoadHomeUseCaseProtocol {
    private(set) var calls = 0
    func execute() async throws -> HomeLoadResultModel {
        calls += 1
        return HomeLoadResultModel(model: .full, inviteLink: nil)
    }
}

@MainActor
private struct NoCellar: AddWineToCellarUseCaseProtocol {
    func execute(_ wine: Wine) async throws {}
}

@MainActor
private struct NoRating: RateWineUseCaseProtocol {
    func execute(_ wine: Wine, verdict: Verdict, addToCellar: Bool) async throws -> [AxisChange] { [] }
}

// MARK: HOME-R10c · Só o que segue o mapa

@MainActor
struct HomeMatchRefreshTests {
    private let loader = LoaderSpy()
    let palate = PalateStateStub()
    let ranking = WineRankingSpy()

    private func loadedViewModel() async -> HomeViewModel {
        let model = HomeViewModel(loadHomeUseCase: loader, loadPalateStateUseCase: palate, rankWinesUseCase: ranking,
                                  addWineToCellarUseCase: NoCellar(), rateWineUseCase: NoRating(),
                                  coordinator: HomeCoordinator(onOpenCourse: { _ in }, onOpenLearn: { _ in }),
                                  now: Date.init, calendar: .current, curtainDuration: .zero)
        await model.load()
        return model
    }

    private func hero(_ model: HomeViewModel) -> Wine? {
        guard case let .topMatch(wine) = model.uiModel.content?.cards.first(where: { $0.kind == "topMatch" }) else { return nil }
        return wine
    }

    private func palateWines(_ model: HomeViewModel) -> [Wine] {
        guard case let .winesForPalate(suggestions) = model.uiModel.content?.cards.first(where: { $0.kind == "winesForPalate" }) else { return [] }
        return suggestions.map(\.wine)
    }

    @Test func HOME_R10c_theMapMoved_onlyTheMatchIsReadAgain_underTheCurtain() async throws {
        let model = await loadedViewModel()
        let other = try #require(HomeContentModel.full.catalog.first { $0.id != hero(model)?.id })
        var curtain: [Bool] = []
        let subscription = model.$uiModel.map(\.isRefreshingMatches).removeDuplicates().sink { curtain.append($0) }
        defer { subscription.cancel() }

        palate.state.palateMap = other.profile
        await model.refreshMatches()

        #expect(loader.calls == 1)
        #expect(ranking.calls == 1)
        #expect(hero(model)?.id == other.id)
        #expect(model.uiModel.content?.palateMap == other.profile)
        // Down, up while the wines are read, down again with the new cards.
        #expect(curtain == [false, true, false])
    }

    @Test func HOME_R10c_newCardsAndTheEndOfTheCurtain_arriveTogether() async throws {
        let model = await loadedViewModel()
        let before = try #require(hero(model))
        let other = try #require(HomeContentModel.full.catalog.first { $0.id != before.id })
        var whileLoading: Set<String> = []
        let subscription = model.$uiModel.sink { ui in
            guard ui.isRefreshingMatches, case let .topMatch(wine)? = ui.content?.cards.first(where: { $0.kind == "topMatch" }) else { return }
            whileLoading.insert(wine.id)
        }
        defer { subscription.cancel() }

        palate.state.palateMap = other.profile
        await model.refreshMatches()

        // Under the curtain the card still holds the old wine; the new one comes with the curtain's end.
        #expect(whileLoading == [before.id])
        #expect(hero(model)?.id == other.id)
        #expect(model.uiModel.isRefreshingMatches == false)
    }

    @Test func HOME_R10c_nothingTheMatchFollowsChanged_noCurtainAndNoRanking() async throws {
        let model = await loadedViewModel()
        var raised = false
        let subscription = model.$uiModel.sink { if $0.isRefreshingMatches { raised = true } }
        defer { subscription.cancel() }

        // A note that only changed its text.
        await model.refreshMatches()

        #expect(!raised)
        #expect(ranking.calls == 0)
        #expect(loader.calls == 1)
    }

    @Test func HOME_R23_aWineThatWentToTheCellar_leavesTheList_withoutCurtainOrRanking() async throws {
        let model = await loadedViewModel()
        let listed = try #require(palateWines(model).first)
        var raised = false
        let subscription = model.$uiModel.sink { if $0.isRefreshingMatches { raised = true } }
        defer { subscription.cancel() }

        palate.state.cellarWineKeys = [listed.id]
        await model.refreshMatches()

        #expect(!raised)
        #expect(ranking.calls == 0)
        #expect(loader.calls == 1)
        #expect(model.uiModel.cellarWineKeys == [listed.id])
        #expect(!palateWines(model).contains { $0.id == listed.id })
    }

    @Test func HOME_R10c_aRatingThatLeftTheMapWhereItWas_rebuildsTheList_withoutRanking() async throws {
        let model = await loadedViewModel()
        palate.state.ratedVerdicts = ["alvarinho": .maybe]
        await model.refreshMatches()
        #expect(ranking.calls == 0)
        #expect(loader.calls == 1)
        #expect(model.uiModel.ratedVerdicts == ["alvarinho": .maybe])
    }

    @Test func HOME_R10c_notesChanged_areReadOnce_whenTheHomeIsShownAgain() async throws {
        let model = await loadedViewModel()
        let other = try #require(HomeContentModel.full.catalog.first { $0.id != hero(model)?.id })

        // Shown again with nothing changed: nothing is read.
        await model.loadIfNeeded()
        #expect(palate.calls == 0)

        // Three notes edited in the Cellar: nothing is read until the Home is back.
        palate.state.palateMap = other.profile
        model.palateChanged()
        model.palateChanged()
        model.palateChanged()
        #expect(palate.calls == 0)

        await model.loadIfNeeded()
        #expect(palate.calls == 1)
        #expect(ranking.calls == 1)
        #expect(hero(model)?.id == other.id)

        await model.loadIfNeeded()
        #expect(palate.calls == 1)
        #expect(loader.calls == 1)
    }

    @Test func HOME_R10c_beforeTheFirstLoad_theWholeHomeIsRead() async {
        let model = HomeViewModel(loadHomeUseCase: loader, loadPalateStateUseCase: palate, rankWinesUseCase: ranking,
                                  addWineToCellarUseCase: NoCellar(), rateWineUseCase: NoRating(),
                                  coordinator: HomeCoordinator(onOpenCourse: { _ in }, onOpenLearn: { _ in }),
                                  now: Date.init, calendar: .current, curtainDuration: .zero)
        await model.refreshMatches()
        #expect(loader.calls == 1)
        #expect(palate.calls == 0)
        #expect(model.uiModel.content != nil)
    }
}
