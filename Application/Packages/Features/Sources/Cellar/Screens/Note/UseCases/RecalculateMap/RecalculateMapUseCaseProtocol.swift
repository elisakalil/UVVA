import Core

@MainActor
protocol RecalculateMapUseCaseProtocol {
    /// Rebuilds the map with every rating of `wineKey` given `verdict`, or without them when it is nil (CELLAR-R29).
    func execute(changing wineKey: String, to verdict: Verdict?) async throws
}
