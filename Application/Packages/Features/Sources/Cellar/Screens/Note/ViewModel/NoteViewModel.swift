import Combine
import Core
import Foundation
import OSLog

/// A saved note (CELLAR.md §5): the wine as the Home's wine sheet shows it, with the photos and the note, read only.
/// Edit opens it in the new note; Delete takes it out of the Cellar.
@MainActor
public final class NoteViewModel: NoteViewModelProtocol {
    @Published public private(set) var uiModel = NoteUIModel()
    public nonisolated let id: String

    private var entry: CellarEntry { didSet { refresh() } }
    private var wine: Wine? { didSet { refresh() } }
    /// The user's map, for the match and the second map.
    private var palate: PalateMap? { didSet { refresh() } }
    private var isWorking = false { didSet { refresh() } }
    private var isConfirmingDelete = false { didSet { refresh() } }
    private var errorText: String? { didSet { refresh() } }

    private let loadNote: any LoadNoteUseCaseProtocol
    private let deleteNote: any DeleteNoteUseCaseProtocol
    private let maps: (any PalateMapRepository)?
    /// The Cellar reads its entries again; `true` when the note left it.
    private let onChange: (_ deleted: Bool) -> Void
    /// The note was deleted: its sheet closes (CELLAR-R28).
    private let onClose: () -> Void
    /// CELLAR-R27: the entry and the wine as shown, for the new note to open with.
    private let onEdit: (CellarEntry, Wine) -> Void
    private let now: () -> Date
    private let logger = Logger(subsystem: "app.uvva", category: "cellar")

    init(entry: CellarEntry, loadNote: any LoadNoteUseCaseProtocol, deleteNote: any DeleteNoteUseCaseProtocol,
         maps: (any PalateMapRepository)? = nil, now: @escaping () -> Date = Date.init,
         onChange: @escaping (Bool) -> Void, onClose: @escaping () -> Void,
         onEdit: @escaping (CellarEntry, Wine) -> Void = { _, _ in }) {
        id = entry.id
        self.entry = entry
        self.loadNote = loadNote
        self.deleteNote = deleteNote
        self.maps = maps
        self.now = now
        self.onChange = onChange
        self.onClose = onClose
        self.onEdit = onEdit
        refresh()
    }

    public func load() async {
        wine = await loadNote.execute(entry.id)
        palate = try? await maps?.currentMap()
    }

    public func edit() {
        onEdit(entry, builder.paperWine)
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

    private var builder: NotePresentationBuilder {
        NotePresentationBuilder(entry: entry, wine: wine, palate: palate, resources: uiModel.resources, now: now())
    }

    private func refresh() {
        let builder = builder
        var model = uiModel
        model.addedText = model.resources.added(builder.date)
        model.coverTag = builder.coverTag
        model.photoFront = entry.photoFront
        model.photoBack = entry.photoBack
        model.content = builder.content
        model.note = entry.note
        model.isWorking = isWorking
        model.isConfirmingDelete = isConfirmingDelete
        model.errorText = errorText
        uiModel = model
    }
}
