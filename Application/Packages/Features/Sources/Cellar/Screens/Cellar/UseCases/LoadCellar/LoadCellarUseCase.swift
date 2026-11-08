import Core

/// Reads every entry of the Cellar, newest first (CELLAR-R02).
struct LoadCellarUseCase: LoadCellarUseCaseProtocol {
    let cellar: any CellarRepository

    func execute() async throws -> [CellarEntry] {
        try await cellar.entries()
    }
}
