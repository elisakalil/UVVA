import Core
import Foundation

/// The map, its ratings and the Cellar's keys: everything the match cards follow, short of the catalog.
@MainActor
struct LoadPalateStateUseCase: LoadPalateStateUseCaseProtocol {
    let maps: any PalateMapRepository
    let cellar: any CellarRepository

    func execute() async throws -> PalateStateModel {
        guard let map = try await maps.currentMap() else { throw PreparationError.missingMap }
        let history = try await maps.history()
        return PalateStateModel(
            palateMap: map,
            ratedWineIDs: try await cellar.tastedWineKeys().union(Rating.wineKeys(in: history)),
            lastRating: Rating.last(in: history),
            cellarWineKeys: try await cellar.wineKeys())
    }

    enum PreparationError: LocalizedError {
        case missingMap

        var errorDescription: String? { "Your palate map could not be loaded." }
    }
}
