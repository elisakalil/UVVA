import Core
import Foundation
import Testing
@testable import Cellar

@MainActor
struct CellarViewModelTests {
    private func make(_ entries: [CellarEntry], preferences: PreferencesStub = PreferencesStub()) async -> CellarViewModel {
        let model = CellarViewModel(loadCellar: CellarLoaderStub(entries: entries), preferences: preferences,
                                    bannerDuration: .milliseconds(10)) { entry, owner in
            NoteViewModel(entry: entry, loadNote: NoteLoaderStub(), saveNote: SaveNoteSpy(), deleteNote: DeleteNoteSpy(),
                          onChange: { _ in }, onClose: { [weak owner] in owner?.closeNote() })
        }
        await model.load()
        return model
    }

    private let douro = [Entries.entry("vale-meao", type: "Red", region: "Douro", verdict: .yes),
                         Entries.entry("redoma", type: "White", region: "Douro")]

    // MARK: CELLAR-R05 · Vazio

    @Test func CELLAR_R05_emptyCellar_filtersAreInactive() async {
        let model = await make([])
        #expect(model.uiModel.state == .empty)
        #expect(!model.uiModel.areFiltersEnabled)
        model.openFilter(.type)
        #expect(model.uiModel.filterSheet == nil)
    }

    // MARK: CELLAR-R07 · Vista guardada

    @Test func CELLAR_R07_firstOpen_isTheGrid() async {
        #expect(await make(douro).uiModel.viewMode == .grid)
    }

    @Test func CELLAR_R07_listChosen_opensInListNextTime() async {
        let preferences = PreferencesStub()
        let first = await make(douro, preferences: preferences)
        first.selectViewMode(.list)
        #expect(first.uiModel.viewMode == .list)
        #expect(await make(douro, preferences: preferences).uiModel.viewMode == .list)
    }

    // MARK: CELLAR-R10 · Filtros

    @Test func CELLAR_R10_pickingAValue_filtersTheItems() async {
        let model = await make(douro)
        model.openFilter(.type)
        model.pick("White")
        #expect(model.uiModel.items.map(\.id) == ["redoma"])
        #expect(model.uiModel.chips.first { $0.facet == .type }?.label == "White")
        #expect(model.uiModel.isFiltered)
    }

    @Test func pickingTheSameValue_turnsTheFilterOff() async {
        let model = await make(douro)
        model.openFilter(.type)
        model.pick("White")
        model.pick("White")
        #expect(model.uiModel.items.count == 2)
        #expect(!model.uiModel.isFiltered)
    }

    @Test func anyValue_clearsTheOpenFilter_andClosesTheSheet() async {
        let model = await make(douro)
        model.openFilter(.type)
        model.pick("White")
        model.clearOpenFilter()
        #expect(model.uiModel.filterSheet == nil)
        #expect(model.uiModel.items.count == 2)
    }

    @Test func clear_removesEveryFilter() async {
        let model = await make(douro)
        model.openFilter(.type)
        model.pick("Red")
        model.openFilter(.region)
        model.pick("Douro")
        model.clearFilters()
        #expect(!model.uiModel.isFiltered)
        #expect(model.uiModel.items.count == 2)
    }

    // MARK: CELLAR-R11, R12 · Pesquisa

    @Test func CELLAR_R11_search_showsTheCountAndRows() async {
        let model = await make(douro)
        model.updateQuery("douro")
        #expect(model.uiModel.isSearching)
        #expect(model.uiModel.searchCount == "2 notes")
        #expect(model.uiModel.searchResults.count == 2)
    }

    @Test func CELLAR_R12_cancel_backToTheCellarWithoutSearch() async {
        let model = await make(douro)
        model.updateQuery("Rioja")
        #expect(model.uiModel.searchResults.isEmpty)
        #expect(model.uiModel.noResultsText == "No notes for “Rioja”")
        model.updateQuery("")
        #expect(!model.uiModel.isSearching)
        #expect(model.uiModel.items.count == 2)
    }

    // MARK: Banner

    @Test func banner_showsOnTheFirstTwoVisitsOnly() async throws {
        let preferences = PreferencesStub()
        for _ in 0..<2 {
            let model = await make(douro, preferences: preferences)
            #expect(model.uiModel.isBannerVisible)
            try await Task.sleep(for: .milliseconds(50))
            #expect(!model.uiModel.isBannerVisible)
        }
        #expect(!(await make(douro, preferences: preferences)).uiModel.isBannerVisible)
    }

    @Test func banner_neverShowsOnAnEmptyCellar() async {
        let preferences = PreferencesStub()
        #expect(!(await make([], preferences: preferences)).uiModel.isBannerVisible)
        #expect(preferences.bannerViews == 0)
    }

    // MARK: CELLAR-R13 · Abrir e voltar

    @Test func CELLAR_R13_open_andBack() async {
        let model = await make(douro)
        model.openNote("redoma")
        #expect(model.note?.id == "redoma")
        model.note?.close()
        #expect(model.note == nil)
    }

    @Test func open_anUnknownWine_doesNothing() async {
        let model = await make(douro)
        model.openNote("nope")
        #expect(model.note == nil)
    }
}
