@MainActor
protocol LoadPalateStateUseCaseProtocol {
    func execute() async throws -> PalateStateModel
}
