import Core
import Match

@MainActor
protocol RateWineUseCaseProtocol {
    /// Moves the map with the verdict and, with `addToCellar`, keeps the wine as Tasted; returns the axes that went up or down.
    func execute(_ wine: Wine, verdict: Verdict, addToCellar: Bool) async throws -> [AxisChange]
}
