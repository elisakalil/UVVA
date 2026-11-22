import Core

@MainActor
protocol LoadTasteHistoryUseCaseProtocol {
    /// The wines the user rated, for the grape and region lines of the wine sheet.
    func execute() async throws -> TasteHistory
}
