import Foundation

/// Finds catalog wines by their wineKey: the saved note's reading and the map rebuild need the wine's profile (CELLAR-R26, R29).
public protocol WineLookup: Sendable {
    /// The wines of the catalog among `keys`; a key not in the Content store is left out.
    func wines(keys: Set<String>) async throws -> [String: Wine]
}
