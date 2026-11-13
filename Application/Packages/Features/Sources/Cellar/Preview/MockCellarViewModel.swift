#if DEBUG
import Combine
import Core
import Foundation

/// A Cellar with a few wines, for the preview.
@MainActor
final class MockCellarViewModel: CellarViewModelProtocol {
    @Published var uiModel: CellarUIModel
    @Published var note: MockNoteViewModel?

    init() {
        let entries = [
            CellarEntry(id: "1", name: "Quinta do Vale Meão", vintage: 2019, type: "Red", region: "Douro", country: "Portugal",
                        grapes: ["Touriga Nacional"], status: .tasted, verdict: .yes, createdAt: .now),
            CellarEntry(id: "2", name: "Barolo Bussia", producer: "Aldo Conterno", vintage: 2016, type: "Red", region: "Piemonte",
                        country: "Italy", grapes: ["Nebbiolo"], status: .tasted, verdict: .maybe, createdAt: .now),
            CellarEntry(id: "3", name: "Baga Bruto", producer: "Luís Pato", vintage: 2020, type: "Sparkling", region: "Bairrada",
                        country: "Portugal", grapes: ["Baga"], status: .wantToTry, createdAt: .now)
        ]
        let builder = CellarPresentationBuilder(entries: entries, filters: [:], openFacet: nil, query: "")
        var model = CellarUIModel()
        model.state = builder.state
        model.items = builder.items
        model.chips = builder.chips
        model.areFiltersEnabled = true
        uiModel = model
    }

    func load() async {}
    func openNote(_ wineKey: String) { note = MockNoteViewModel() }
    func closeNote() { note = nil }
    func noteDismissed() {}
    func add() {}
    func selectViewMode(_ mode: CellarViewMode) { uiModel.viewMode = mode }
    func openFilter(_ facet: CellarFacet) {}
    func closeFilter() {}
    func pick(_ value: String) {}
    func clearOpenFilter() {}
    func clearFilters() {}
    func updateQuery(_ query: String) { uiModel.query = query }
}
#endif
