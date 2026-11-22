import Combine
import Core
import Foundation
import OSLog

/// A saved note (CELLAR.md §5): the wine as the Home's wine sheet shows it, with the photos and the note.
/// Edit opens it in the new note; Delete takes it out of the Cellar.
@MainActor
public final class NoteViewModel: NoteViewModelProtocol {
    @Published public private(set) var uiModel = NoteUIModel()
    public nonisolated let id: String

    private var entry: CellarEntry { didSet { refresh() } }
    private var isReadingPhotos = false
    private var wine: Wine? { didSet { refresh() } }
    /// The user's map, for the match and the second map.
    private var palate: PalateMap? { didSet { refresh() } }
    /// The wines the user rated, for what they know of the grape and the region. Nil until it loads.
    private var history: TasteHistory? { didSet { refresh() } }
    private var isWorking = false { didSet { refresh() } }
    private var isConfirmingDelete = false { didSet { refresh() } }
    private var errorText: String? { didSet { refresh() } }

    private let loadNote: any LoadNoteUseCaseProtocol
    private let deleteNote: any DeleteNoteUseCaseProtocol
    private let saveRating: ((CellarEntry, Wine, Verdict, Int?, String?) async throws -> Void)?
    private let maps: (any PalateMapRepository)?
    private let cellar: (any CellarRepository)?
    /// The Cellar reads its entries again; `true` when the note left it.
    private let onChange: (_ deleted: Bool) -> Void
    /// The note was deleted: its sheet closes (CELLAR-R28).
    private let onClose: () -> Void
    /// CELLAR-R27: the entry and the wine as shown, for the new note to open with.
    private let onEdit: (CellarEntry, Wine) -> Void
    private let now: () -> Date
    private let logger = Logger(subsystem: "app.uvva", category: "cellar")

    init(entry: CellarEntry, loadNote: any LoadNoteUseCaseProtocol, deleteNote: any DeleteNoteUseCaseProtocol,
         maps: (any PalateMapRepository)? = nil, cellar: (any CellarRepository)? = nil, now: @escaping () -> Date = Date.init,
         onChange: @escaping (Bool) -> Void, onClose: @escaping () -> Void,
         onEdit: @escaping (CellarEntry, Wine) -> Void = { _, _ in },
         saveRating: ((CellarEntry, Wine, Verdict, Int?, String?) async throws -> Void)? = nil) {
        id = entry.id
        self.entry = entry
        self.loadNote = loadNote
        self.deleteNote = deleteNote
        self.maps = maps
        self.cellar = cellar
        self.saveRating = saveRating
        self.now = now
        self.onChange = onChange
        self.onClose = onClose
        self.onEdit = onEdit
        refresh()
    }

    func startReadingPhotos() {
        isReadingPhotos = true
        refresh()
    }

    func finishReadingPhotos() {
        isReadingPhotos = false
        refresh()
    }

    func setFullEntry(_ fullEntry: CellarEntry) {
        isReadingPhotos = false
        entry = fullEntry
    }

    public func load() async {
        wine = await loadNote.execute(entry.id)
        palate = try? await maps?.currentMap()
        await loadHistory()
    }

    /// The verdicts of the Cellar, this note's included: a new rating moves the grape and region lines.
    private func loadHistory() async {
        if let entries = try? await cellar?.entrySummaries() {
            history = TasteHistory(entries: entries)
        }
    }

    public func edit() {
        guard !isReadingPhotos, !isWorking else { return }
        onEdit(entry, builder.paperWine)
    }

    /// The rating sheet (CELLAR-R18): the verdict, the score and "Your note", kept together; an emptied note goes.
    public func rate(_ verdict: Verdict, score: Int?, note: String) async -> Bool {
        guard !isWorking, !isReadingPhotos, let saveRating else { return false }
        isWorking = true
        errorText = nil
        defer { isWorking = false }
        do {
            let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
            let kept = trimmed.isEmpty ? nil : trimmed
            try await saveRating(entry, wine ?? builder.paperWine, verdict, score, kept)
            var ratedEntry = entry
            ratedEntry.note = kept
            ratedEntry.status = .tasted
            ratedEntry.verdict = verdict
            ratedEntry.score = score
            entry = ratedEntry
            palate = try? await maps?.currentMap()
            await loadHistory()
            onChange(false)
            return true
        } catch {
            logger.error("Rating not saved: \(error.localizedDescription, privacy: .public)")
            errorText = uiModel.resources.ratingErrorText
            return false
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

    private var builder: NotePresentationBuilder {
        NotePresentationBuilder(entry: entry, wine: wine, palate: palate, history: history, resources: uiModel.resources, now: now())
    }

    private func refresh() {
        let builder = builder
        var model = uiModel
        model.addedText = model.resources.added(builder.date)
        model.coverTag = builder.coverTag
        model.verdict = entry.verdict
        model.score = entry.score
        model.photoFront = entry.photoFront
        model.photoBack = entry.photoBack
        model.wineKey = entry.id
        model.isReadingPhotos = isReadingPhotos
        model.content = builder.content
        model.match = builder.match
        model.insights = builder.insights
        model.note = entry.note
        model.isWorking = isWorking
        model.isConfirmingDelete = isConfirmingDelete
        model.errorText = errorText
        uiModel = model
    }
}
