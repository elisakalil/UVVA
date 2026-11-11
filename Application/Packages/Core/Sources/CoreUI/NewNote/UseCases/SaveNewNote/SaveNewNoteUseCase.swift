import Core
import Foundation
import Match

@MainActor
struct SaveNewNoteUseCase: SaveNewNoteUseCaseProtocol {
    let cellar: any CellarRepository
    let catalog: any LabelCatalogRepository
    let maps: any PalateMapRepository
    let recalculate: any RecalculateMapUseCaseProtocol
    let now: () -> Date

    func execute(_ draft: NewNoteDraft) async throws {
        // A wine the catalog does not have (scanned, or another vintage) joins it first, so the note and the map
        // find it; a catalog wine is left as it is.
        let catalogWine = draft.originalWine ?? draft.wine
        try await catalog.addScanned(catalogWine)
        let before = try await cellar.save(draft)
        guard draft.status == .tasted, let verdict = draft.verdict else { return }
        // The wine may have been rated on the Home without going to the Cellar (HOME-R24): that rating is its old one.
        let rated = Rating.verdicts(in: try await maps.history())[draft.wine.id]
        if let old = before?.verdict ?? rated {
            // CELLAR-R13b, D8: a new verdict for the same wine replaces its rating.
            if old != verdict { try await recalculate.execute(changing: draft.wine.id, to: verdict) }
        } else {
            // CELLAR-R19: the first rating moves the map once (SHARED-R09, QUIZ-R22).
            guard let map = try await maps.currentMap() else { return }
            let update = MapUpdate.apply(verdict, wine: catalogWine.profile, to: map)
            try await maps.saveRatedMap(update.map, wineKey: draft.wine.id, verdict: verdict, at: now())
        }
    }
}
