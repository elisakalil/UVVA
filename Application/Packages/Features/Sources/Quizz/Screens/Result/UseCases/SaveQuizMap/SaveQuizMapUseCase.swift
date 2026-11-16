import Core
import Foundation

@MainActor
struct SaveQuizMapUseCase: SaveQuizMapUseCaseProtocol {
    let maps: any PalateMapRepository
    let now: () -> Date

    /// The map, with the answers it was drawn from, kept out of sight (QUIZ-R04a).
    func execute(_ map: PalateMap, answers: [PalateAxis: Int]) async throws {
        try await maps.saveQuizMap(map, answers: answers, at: now())
    }
}
