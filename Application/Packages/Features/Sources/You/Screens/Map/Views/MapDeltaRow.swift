import Core
import Foundation
import Match

struct MapDeltaRow: Equatable, Identifiable {
    var axis: PalateAxis
    var value: Double

    var id: PalateAxis { axis }
    var delta: String {
        let magnitude = abs(value).formatted(.number.precision(.fractionLength(1)))
        guard abs(value) >= AxisChange.threshold else { return magnitude }
        return (value > 0 ? "↑" : "↓") + " " + magnitude
    }
}
