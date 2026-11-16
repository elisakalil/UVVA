import Core

@MainActor
protocol DrawQuizMapUseCaseProtocol {
    /// "Draw the map" (QUIZ-R04a to R04c): the answers, settled among real wines.
    func execute(_ answers: [PalateAxis: Int]) async -> PalateMap
}
