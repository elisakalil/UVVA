import Core
import Foundation

/// What the cards that follow the map are read from, without the catalog: cheap to read, so the Home can tell whether
/// those cards are out of date before it ranks the wines again (HOME-R10c).
struct PalateStateModel: Equatable, Sendable {
    var palateMap: PalateMap
    /// HOME-R24: the verdict of each wine rated since the Quiz, so its sheet only asks about the Cellar.
    var ratedVerdicts: [String: Verdict]
    /// HOME-R15: the last rating's moves.
    var lastRating: Rating?
    /// HOME-R23: the wines in the Cellar, which leave "Wines for your palate".
    var cellarWineKeys: Set<String>
}
