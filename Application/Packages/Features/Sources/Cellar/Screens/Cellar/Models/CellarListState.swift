import Foundation

/// What the Cellar shows below its filters.
enum CellarListState: Equatable {
    /// Nothing in the Cellar yet (CELLAR-R05).
    case empty
    /// Wines in the Cellar, none with these filters.
    case noMatches
    case items
}
