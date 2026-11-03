import Core
import Foundation
import Match

/// Map (YOU-R09 to R13).
struct MapUIModel: Equatable {
    var readOn: String
    var map: PalateMap
    /// The axes drawn strong on the chart (QUIZ-R16).
    var highlighted: [PalateAxis]
    /// "Acidity · Fruit · Body", on the shared card (YOU-R12).
    var dominantPhrase: String
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
