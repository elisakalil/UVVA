import Core

@MainActor
protocol ReadManualUseCaseProtocol {
    /// "Continue" in "Fill in by hand" (CELLAR-R23): the catalog wine with that name, or a wine made of what was
    /// typed, with its map estimated from the wines most like it.
    func execute(_ facts: LabelFacts) async throws -> Wine
}
