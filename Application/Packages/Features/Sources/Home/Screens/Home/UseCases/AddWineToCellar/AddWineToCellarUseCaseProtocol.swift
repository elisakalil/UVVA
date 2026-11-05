import Core

@MainActor
protocol AddWineToCellarUseCaseProtocol {
    func execute(_ wine: Wine) async throws
}
