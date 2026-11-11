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
    public func makeViewModel(onAdd: @escaping () -> Void = {}, onNoteChange: @escaping () -> Void = {}) -> CellarViewModel {
        let recalculate = recalculate
        let load = LoadNoteUseCase(wines: wines)
        let save = SaveNoteUseCase(cellar: cellar, maps: maps, wines: wines, recalculate: recalculate, now: now)
        let delete = DeleteNoteUseCase(cellar: cellar, recalculate: recalculate)
        return CellarViewModel(
            loadCellar: LoadCellarUseCase(cellar: cellar),
            preferences: preferences,
            onAdd: onAdd,
            onNoteChange: onNoteChange
        ) { entry, owner in
            NoteViewModel(entry: entry, loadNote: load, saveNote: save, deleteNote: delete,
                          onChange: { [weak owner] _ in owner?.noteChanged() },
                          onClose: { [weak owner] in owner?.closeNote() })
        }
    }
}
