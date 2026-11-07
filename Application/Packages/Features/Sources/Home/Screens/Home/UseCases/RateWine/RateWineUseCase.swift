import Core
import Foundation
import Match

/// HOME-R24: "Would you drink it again?" from the Home. The map moves (SHARED-R09, QUIZ-R22) and the rating joins its
/// history; if the user adds it to the Cellar, it goes there as Tasted with its verdict (CELLAR-R13c). Only the axes that
/// moved by the threshold come back (QUIZ-R23).
@MainActor
struct RateWineUseCase: RateWineUseCaseProtocol {
    let maps: any PalateMapRepository
    let cellar: any CellarRepository
    let now: () -> Date

    func execute(_ wine: Wine, verdict: Verdict, addToCellar: Bool) async throws -> [AxisChange] {
        guard let map = try await maps.currentMap() else { throw RatingError.missingMap }
        let update = MapUpdate.apply(verdict, wine: wine.profile, to: map)
        try await maps.saveRatedMap(update.map, wineKey: wine.id, verdict: verdict, at: now())
        if addToCellar { try await cellar.addTasted(wine, verdict: verdict) }
        return update.changes.filter { $0.wentUp || $0.wentDown }
    }

    enum RatingError: Error {
        /// There is no map to move before the first Quiz.
        case missingMap
    }
}
