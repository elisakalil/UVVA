import Core
import Foundation
import Match

@MainActor
public struct CellarFactory: CellarFactoryProtocol {
    private let cellar: any CellarRepository
    private let maps: any PalateMapRepository
    private let rewriter: any PalateHistoryRewriting
    private let wines: any WineLookup
    /// Where scanned wines are kept, so deleting a note takes its scanned wine too (CELLAR-R28).
    private let labelCatalog: (any LabelCatalogRepository)?
    private let preferences: any CellarPreferencesProtocol
    private let now: () -> Date

    public init(
        cellar: any CellarRepository,
        maps: any PalateMapRepository,
        rewriter: any PalateHistoryRewriting,
        wines: any WineLookup,
        labelCatalog: (any LabelCatalogRepository)? = nil,
        preferences: any CellarPreferencesProtocol = CellarPreferences(),
        now: @escaping () -> Date = Date.init
    ) {
        self.cellar = cellar
        self.maps = maps
        self.rewriter = rewriter
        self.wines = wines
        self.labelCatalog = labelCatalog
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
        let delete = DeleteNoteUseCase(cellar: cellar, recalculate: recalculate, catalog: labelCatalog)
        let cellar = cellar
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
                          onChange: { [weak owner] deleted in
                              if deleted {
                                  owner?.noteDeleted(entry.id)
                              } else {
                                  owner?.noteRated(entry.id)
                              }
                          },
                          onClose: { [weak owner] in owner?.closeNote() },
                          onEdit: { [weak owner] entry, wine in owner?.editNote(entry, wine: wine) },
                          saveRating: { entry, wine, verdict, score, note in
                              try await cellar.update(entry.id, verdict: verdict, score: score, note: note)
                              try await RecordWineRatingUseCase(maps: maps, recalculate: recalculate)
                                  .execute(verdict, for: entry.id, profile: wine.profile, at: now)
                          })
        }
    }
}
