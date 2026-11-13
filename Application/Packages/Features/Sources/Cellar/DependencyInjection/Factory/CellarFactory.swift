import Core
import Foundation
import Match

@MainActor
public struct CellarFactory: CellarFactoryProtocol {
    private let cellar: any CellarRepository
    private let maps: any PalateMapRepository
    private let rewriter: any PalateHistoryRewriting
    private let wines: any WineLookup
    private let preferences: any CellarPreferencesProtocol
    private let now: () -> Date

    public init(
        cellar: any CellarRepository,
        maps: any PalateMapRepository,
        rewriter: any PalateHistoryRewriting,
        wines: any WineLookup,
        preferences: any CellarPreferencesProtocol = CellarPreferences(),
        now: @escaping () -> Date = Date.init
    ) {
        self.cellar = cellar
        self.maps = maps
        self.rewriter = rewriter
        self.wines = wines
        self.preferences = preferences
        self.now = now
    }

    private var recalculate: RecalculateMapUseCase {
        RecalculateMapUseCase(history: maps, rewriter: rewriter, wines: wines)
    }

    /// The tab. `onAdd` is the `+`: the app opens the shared new note (CELLAR-R14).
    /// `onNoteChange` tells the app a note was saved or deleted, which may have moved the map (CELLAR-R29).
    /// `onEditNote` opens the shared new note on a saved one, to edit it there (CELLAR-R27).
    public func makeViewModel(onAdd: @escaping () -> Void = {}, onNoteChange: @escaping () -> Void = {},
                              onEditNote: @escaping (CellarEntry, Wine) -> Void = { _, _ in }) -> CellarViewModel {
        let recalculate = recalculate
        let load = LoadNoteUseCase(wines: wines)
        let delete = DeleteNoteUseCase(cellar: cellar, recalculate: recalculate)
        let maps = maps
        let now = now
        return CellarViewModel(
            loadCellar: LoadCellarUseCase(cellar: cellar),
            preferences: preferences,
            onAdd: onAdd,
            onNoteChange: onNoteChange,
            onEditNote: onEditNote
        ) { entry, owner in
            NoteViewModel(entry: entry, loadNote: load, deleteNote: delete, maps: maps, now: now,
                          onChange: { [weak owner] _ in owner?.noteChanged() },
                          onClose: { [weak owner] in owner?.closeNote() },
                          onEdit: { [weak owner] entry, wine in owner?.editNote(entry, wine: wine) })
        }
    }
}
