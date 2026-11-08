import Core
import Foundation

@MainActor
public struct CellarFactory: CellarFactoryProtocol {
    private let cellar: any CellarRepository
    private let maps: any PalateMapRepository
    private let rewriter: any PalateHistoryRewriting
    private let wines: any WineLookup
    private let labelCatalog: any LabelCatalogRepository
    private let reader: any LabelReading
    private let structurer: any LabelStructuring
    private let camera: any CameraAuthorizing
    private let preferences: any CellarPreferencesProtocol
    private let now: () -> Date

    public init(cellar: any CellarRepository, maps: any PalateMapRepository, rewriter: any PalateHistoryRewriting,
                wines: any WineLookup, labelCatalog: any LabelCatalogRepository, reader: any LabelReading,
                structurer: any LabelStructuring, camera: any CameraAuthorizing,
                preferences: any CellarPreferencesProtocol = CellarPreferences(),
                now: @escaping () -> Date = Date.init) {
        self.cellar = cellar
        self.maps = maps
        self.rewriter = rewriter
        self.wines = wines
        self.labelCatalog = labelCatalog
        self.reader = reader
        self.structurer = structurer
        self.camera = camera
        self.preferences = preferences
        self.now = now
    }

    private var recalculate: RecalculateMapUseCase {
        RecalculateMapUseCase(history: maps, rewriter: rewriter, wines: wines)
    }

    /// The tab. `onAdd` is the `+`: the app opens `makeNewNote`, as it does from the Home (CELLAR-R14).
    public func makeViewModel(onAdd: @escaping () -> Void = {}) -> CellarViewModel {
        let recalculate = recalculate
        let load = LoadNoteUseCase(wines: wines)
        let save = SaveNoteUseCase(cellar: cellar, maps: maps, wines: wines, recalculate: recalculate, now: now)
        let delete = DeleteNoteUseCase(cellar: cellar, recalculate: recalculate)
        return CellarViewModel(loadCellar: LoadCellarUseCase(cellar: cellar), preferences: preferences,
                               onAdd: onAdd) { entry, owner in
            NoteViewModel(entry: entry, loadNote: load, saveNote: save, deleteNote: delete,
                          onChange: { [weak owner] _ in owner?.noteChanged() },
                          onClose: { [weak owner] in owner?.closeNote() })
        }
    }

    /// A new note (CELLAR.md §4), with the catalog read once for it.
    public func makeNewNote(onSaved: @escaping () -> Void, onClose: @escaping () -> Void) -> NewNoteViewModel {
        let catalog = LabelCatalogCache(catalog: labelCatalog)
        return NewNoteViewModel(
            prepareCamera: PrepareCameraUseCase(camera: camera),
            readLabel: ReadLabelUseCase(reader: reader, structurer: structurer, catalog: catalog, now: now),
            readManual: ReadManualUseCase(catalog: catalog),
            saveNewNote: SaveNewNoteUseCase(cellar: cellar, catalog: labelCatalog, maps: maps,
                                            recalculate: recalculate, now: now),
            onSaved: onSaved, onClose: onClose)
    }
}
