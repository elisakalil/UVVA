import Core
import Foundation

/// What the cards that follow the map are read from, without the catalog: cheap to read, so the Home can tell whether
/// those cards are out of date before it ranks the wines again (HOME-R10c).
struct PalateStateModel: Equatable, Sendable {
    var palateMap: PalateMap
    /// HOME-R23: the wines rated so far.
    var ratedWineIDs: Set<String>
    /// HOME-R15: the last rating's moves.
    var lastRating: Rating?
    var cellarWineKeys: Set<String>
}
