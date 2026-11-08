import Combine
import Core
import Foundation
import OSLog

/// A saved note (CELLAR.md §5): what was tasted and UVVA's reading; Edit and Delete.
@MainActor
public final class NoteViewModel: NoteViewModelProtocol {
    @Published public private(set) var uiModel = NoteUIModel()
    public nonisolated let id: String

    private var entry: CellarEntry { didSet { refresh() } }
    private var wine: Wine? { didSet { refresh() } }
    private var isEditing = false { didSet { refresh() } }
    private var draftVerdict: Verdict? { didSet { refresh() } }
    private var draftNote = "" { didSet { refresh() } }
    private var isWorking = false { didSet { refresh() } }
    private var isConfirmingDelete = false { didSet { refresh() } }
    private var errorText: String? { didSet { refresh() } }

    private let loadNote: any LoadNoteUseCaseProtocol
    private let saveNote: any SaveNoteUseCaseProtocol
    private let deleteNote: any DeleteNoteUseCaseProtocol
    /// The Cellar reads its entries again; `true` when the note left it.
    private let onChange: (_ deleted: Bool) -> Void
    private let onClose: () -> Void
    private let logger = Logger(subsystem: "app.uvva", category: "cellar")

    init(entry: CellarEntry, loadNote: any LoadNoteUseCaseProtocol, saveNote: any SaveNoteUseCaseProtocol,
         deleteNote: any DeleteNoteUseCaseProtocol, onChange: @escaping (Bool) -> Void, onClose: @escaping () -> Void) {
        id = entry.id
        self.entry = entry
        self.loadNote = loadNote
        self.saveNote = saveNote
        self.deleteNote = deleteNote
        self.onChange = onChange
        self.onClose = onClose
        refresh()
    }

    public func load() async {
        wine = await loadNote.execute(entry.id)
    }

    /// The `‹`: back to the Cellar where it was (CELLAR-R13).
    public func close() { onClose() }

    /// CELLAR-R27: the draft starts from the note as it is.
    public func edit() {
        draftVerdict = entry.verdict
        draftNote = entry.note ?? ""
        errorText = nil
        isEditing = true
    }

    /// "Cancel" drops the changes.
    public func cancelEdit() {
        isEditing = false
        errorText = nil
    }

    public func pick(_ verdict: Verdict) { draftVerdict = verdict }

    public func updateNote(_ text: String) { draftNote = text }

    public func save() async {
        guard isEditing, !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await saveNote.execute(entry, verdict: draftVerdict, note: draftNote)
            let note = draftNote.trimmingCharacters(in: .whitespacesAndNewlines)
            var saved = entry
            if let draftVerdict {
                saved.verdict = draftVerdict
                saved.status = .tasted
            }
            saved.note = note.isEmpty ? nil : note
            entry = saved
            isEditing = false
            onChange(false)
        } catch {
            logger.error("Note not saved: \(error.localizedDescription, privacy: .public)")
            errorText = uiModel.resources.saveErrorText
        }
    }

    public func askToDelete() { isConfirmingDelete = true }

    public func cancelDelete() { isConfirmingDelete = false }

    /// CELLAR-R28: the note leaves the Cellar, and the Cellar comes back.
    public func confirmDelete() async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await deleteNote.execute(entry)
            isConfirmingDelete = false
            onChange(true)
            onClose()
        } catch {
            logger.error("Note not deleted: \(error.localizedDescription, privacy: .public)")
            isConfirmingDelete = false
            errorText = uiModel.resources.deleteErrorText
        }
    }

    private func refresh() {
        let builder = NotePresentationBuilder(entry: entry, wine: wine, resources: uiModel.resources)
        var model = uiModel
        model.isEditing = isEditing
        model.barLabel = isEditing ? model.resources.editNoteText : model.resources.tastingNoteText
        model.date = builder.date
        model.title = entry.name
        model.subtitle = builder.subtitle
        model.again = builder.again
        model.coverTag = builder.coverTag
        model.photoFront = entry.photoFront
        model.photoBack = entry.photoBack
        model.note = entry.note
        model.facts = builder.facts
        model.hasReading = wine != nil
        model.readingText = wine?.originInsight
        model.structure = builder.structure
        model.aromas = builder.aromas
        model.verdicts = builder.verdicts(selected: draftVerdict)
        model.draftNote = draftNote
        model.isWorking = isWorking
        model.isConfirmingDelete = isConfirmingDelete
        model.errorText = errorText
        uiModel = model
    }
}
