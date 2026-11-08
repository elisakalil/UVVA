import Core
import Foundation

/// The map and its axis changes after one wine rating.
struct SnapshotUIModel: Equatable {
    var date: Date
    var map: PalateMap
    var deltas: [MapDeltaRow]
}
