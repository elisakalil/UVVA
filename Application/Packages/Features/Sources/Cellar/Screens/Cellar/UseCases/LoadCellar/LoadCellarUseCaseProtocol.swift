import Core

protocol LoadCellarUseCaseProtocol: Sendable {
    func execute() async throws -> [CellarEntry]
}
