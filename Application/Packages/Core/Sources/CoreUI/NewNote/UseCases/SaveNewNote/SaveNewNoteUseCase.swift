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
        // find it; one scanned before gains what this reading added; a catalog wine is left as it is.
        let catalogWine = draft.originalWine ?? draft.wine
        try await catalog.addScanned(catalogWine)
        try await cellar.save(draft)
        guard draft.selectedVerdict, let verdict = draft.verdict else { return }
        try await RecordWineRatingUseCase(maps: maps, recalculate: recalculate)
            .execute(verdict, for: draft.wine.id, profile: catalogWine.profile, at: now)
    }
}
