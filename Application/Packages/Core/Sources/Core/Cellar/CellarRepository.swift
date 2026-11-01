import Foundation

/// Keeps the Cellar in the Personal store (CELLAR.md).
public protocol CellarRepository: Sendable {
    /// The wineKeys of every entry, tasted or not.
    func wineKeys() async throws -> Set<String>
    /// Adds the wine as Want to try (CELLAR-R01). A wine already in the Cellar stays as it is, so a tasted
    /// entry is never turned back into Not yet.
    func addWantToTry(_ wine: Wine) async throws
}
