import Foundation

/// What the Cellar shows below its filters.
enum CellarListState: Equatable {
    /// The entries were not read yet: nothing below the filters, so the empty state never flashes before the wines.
    case idle
    /// Nothing in the Cellar yet (CELLAR-R05).
    case empty
    /// Wines in the Cellar, none with these filters.
    case noMatches
    case items
}
