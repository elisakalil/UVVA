import Core

@MainActor
protocol LoadHomeUseCaseProtocol {
    func execute() async throws -> HomeLoadResultModel
}
