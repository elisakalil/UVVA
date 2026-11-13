#if DEBUG
import Combine
import Core
import Foundation

/// A saved note, for the preview.
@MainActor
final class MockNoteViewModel: NoteViewModelProtocol {
    let id = "ponto-forte"
    @Published var uiModel: NoteUIModel

    init() {
        let entry = CellarEntry(id: id, name: "Ponto Forte", producer: "Ravasqueira", vintage: 2024, type: "Red",
                                region: "Alentejo", country: "Portugal", origin: "Vinho Regional Alentejano, Portugal",
                                grapes: ["Syrah", "Viognier"], status: .tasted, verdict: .yes,
                                note: "Dry, full, soft tannin. Plum and pepper first, then something floral at the end.",
                                alcohol: 13.5, createdAt: .now)
        let builder = NotePresentationBuilder(entry: entry, wine: nil, palate: PalateMap([.body: 6, .fruit: 8]))
        var model = NoteUIModel()
        model.addedText = model.resources.added(builder.date)
        model.coverTag = builder.coverTag
        model.content = builder.content
        model.note = entry.note
        uiModel = model
    }

    func load() async {}
    func edit() {}
    func askToDelete() { uiModel.isConfirmingDelete = true }
    func cancelDelete() { uiModel.isConfirmingDelete = false }
    func confirmDelete() async {}
}
#endif
