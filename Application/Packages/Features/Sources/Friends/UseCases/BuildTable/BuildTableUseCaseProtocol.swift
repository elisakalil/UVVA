import Core

@MainActor
protocol BuildTableUseCaseProtocol {
    /// The three bottles and their dishes for everyone at the table (FRI-R14).
    func execute(maps: [PalateMap]) async throws -> [TableBottle]
}
