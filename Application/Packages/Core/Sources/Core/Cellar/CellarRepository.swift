import Foundation

/// Keeps the Cellar in the Personal store (CELLAR.md).
public protocol CellarRepository: Sendable {
    /// The wineKeys of every entry, tasted or not.
    func wineKeys() async throws -> Set<String>
    /// Adds the wine as Want to try (CELLAR-R01). A wine already in the Cellar stays as it is, so a tasted
    /// entry is never turned back into Not yet.
    func addWantToTry(_ wine: Wine) async throws
    /// The wineKeys of the wines already rated (SHARED-R11).
    func tastedWineKeys() async throws -> Set<String>
    /// Keeps the wine as Tasted with its verdict (CELLAR-R13c). A wine already in the Cellar, Not yet or
    /// Tasted, is updated in place.
    func addTasted(_ wine: Wine, verdict: Verdict) async throws
}
