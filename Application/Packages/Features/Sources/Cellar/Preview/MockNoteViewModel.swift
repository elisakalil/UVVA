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
        let builder = NotePresentationBuilder(entry: entry, wine: nil)
        var model = NoteUIModel()
        model.barLabel = model.resources.tastingNoteText
        model.date = builder.date
        model.title = entry.name
        model.subtitle = builder.subtitle
        model.again = builder.again
        model.note = entry.note
        model.facts = builder.facts
        model.verdicts = builder.verdicts(selected: .yes)
        uiModel = model
    }

    func load() async {}
    func close() {}
    func edit() { uiModel.isEditing = true }
    func cancelEdit() { uiModel.isEditing = false }
    func pick(_ verdict: Verdict) {}
    func updateNote(_ text: String) { uiModel.draftNote = text }
    func save() async { uiModel.isEditing = false }
    func askToDelete() { uiModel.isConfirmingDelete = true }
    func cancelDelete() { uiModel.isConfirmingDelete = false }
    func confirmDelete() async {}
}
#endif
