import Core
import Foundation

@MainActor
public struct CellarFactory: CellarFactoryProtocol {
    private let cellar: any CellarRepository
    private let maps: any PalateMapRepository
    private let rewriter: any PalateHistoryRewriting
    private let wines: any WineLookup
    private let preferences: any CellarPreferencesProtocol
    private let now: () -> Date

    public init(cellar: any CellarRepository, maps: any PalateMapRepository, rewriter: any PalateHistoryRewriting,
                wines: any WineLookup, preferences: any CellarPreferencesProtocol = CellarPreferences(),
                now: @escaping () -> Date = Date.init) {
        self.cellar = cellar
        self.maps = maps
        self.rewriter = rewriter
        self.wines = wines
        self.preferences = preferences
        self.now = now
    }

    public func makeViewModel() -> CellarViewModel {
        let recalculate = RecalculateMapUseCase(history: maps, rewriter: rewriter, wines: wines)
        let load = LoadNoteUseCase(wines: wines)
        let save = SaveNoteUseCase(cellar: cellar, maps: maps, wines: wines, recalculate: recalculate, now: now)
        let delete = DeleteNoteUseCase(cellar: cellar, recalculate: recalculate)
        return CellarViewModel(loadCellar: LoadCellarUseCase(cellar: cellar), preferences: preferences) { entry, owner in
            NoteViewModel(entry: entry, loadNote: load, saveNote: save, deleteNote: delete,
                          onChange: { [weak owner] _ in owner?.noteChanged() },
                          onClose: { [weak owner] in owner?.closeNote() })
        }
    }
}
