import Core
import Foundation

@MainActor
struct SaveQuizMapUseCase: SaveQuizMapUseCaseProtocol {
    let maps: any PalateMapRepository
    let now: () -> Date

    func execute(_ map: PalateMap) async throws {
        try await maps.saveQuizMap(map, at: now())
    }
}
