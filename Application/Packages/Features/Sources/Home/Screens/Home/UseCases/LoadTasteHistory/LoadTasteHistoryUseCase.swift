import Core

@MainActor
struct LoadTasteHistoryUseCase: LoadTasteHistoryUseCaseProtocol {
    let cellar: any CellarRepository

    func execute() async throws -> TasteHistory {
        TasteHistory(entries: try await cellar.entrySummaries())
    }
}
