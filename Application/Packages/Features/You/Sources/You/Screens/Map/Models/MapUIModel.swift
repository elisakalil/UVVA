import Core
import Foundation
import Match

/// Map (YOU-R09 to R13).
struct MapUIModel: Equatable {
    var readOn: String
    var map: PalateMap
    var top3: [PalateAxis]
    var caption: String
    var readings: [MapReadingRow]
    /// "Over time" shows only once a rated wine has moved the map after the Quiz (YOU-R10).
    var showsOverTime: Bool
    var snapshots: [SnapshotUIModel]
    var selected: Int
    /// The selected snapshot under today's map; nil when it is today's.
    var comparison: PalateMap?
    var deltas: [MapDeltaRow]
    /// "Your last wine raised your tannin." after a rating.
    var lastChange: String?
    var narrative: String
}
