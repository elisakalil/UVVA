import Core

@MainActor
protocol SaveQuizMapUseCaseProtocol {
    func execute(_ map: PalateMap) async throws
}
