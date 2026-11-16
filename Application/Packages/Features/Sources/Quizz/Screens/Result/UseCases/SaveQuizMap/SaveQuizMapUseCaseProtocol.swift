import Core

@MainActor
protocol SaveQuizMapUseCaseProtocol {
    func execute(_ map: PalateMap, answers: [PalateAxis: Int]) async throws
}
