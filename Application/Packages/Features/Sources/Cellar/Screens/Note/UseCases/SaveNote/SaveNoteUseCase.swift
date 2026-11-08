import Core
import Foundation
import Match

@MainActor
struct SaveNoteUseCase: SaveNoteUseCaseProtocol {
    let cellar: any CellarRepository
    let maps: any PalateMapRepository
    let wines: any WineLookup
    let recalculate: any RecalculateMapUseCaseProtocol
    let now: () -> Date

    func execute(_ entry: CellarEntry, verdict: Verdict?, note: String) async throws {
        try await cellar.update(entry.id, verdict: verdict, note: note)
        guard let verdict, verdict != entry.verdict else { return }
        if entry.verdict == nil {
            try await rateForTheFirstTime(entry.id, verdict: verdict)
        } else {
            try await recalculate.execute(changing: entry.id, to: verdict)
        }
    }

    /// CELLAR-R01b: a Not yet wine given a verdict is a new rating, and moves the map once (QUIZ-R22).
    /// A wine outside the catalog has no profile to move it with.
    private func rateForTheFirstTime(_ wineKey: String, verdict: Verdict) async throws {
        guard let map = try await maps.currentMap(),
              let wine = try await wines.wines(keys: [wineKey])[wineKey] else { return }
        let update = MapUpdate.apply(verdict, wine: wine.profile, to: map)
        try await maps.saveRatedMap(update.map, wineKey: wineKey, verdict: verdict, at: now())
    }
}
