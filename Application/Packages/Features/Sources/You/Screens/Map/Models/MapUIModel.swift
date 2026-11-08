import Core
import Foundation
import Match

/// Map (YOU-R09 to R13).
struct MapUIModel: Equatable {
    var historyTitle = String(localized: "Over time", bundle: .module)

    var map: PalateMap
    /// The axes drawn strong on the chart (QUIZ-R16).
    var highlighted: [PalateAxis]
    /// "Acidity · Fruit · Body", on the shared card (YOU-R12).
    var dominantPhrase: String
    var readings: [MapReadingRow]
    var snapshots: [SnapshotUIModel]
    /// "Your last wine raised your tannin." after a rating.
    var lastChange: String?
    var narrative: String

    var historyDeltas: [MapDeltaRow] {
        var totals: [PalateAxis: Double] = [:]
        for row in snapshots.flatMap(\.deltas) {
            totals[row.axis, default: 0] += row.value
        }
        return PalateAxis.allCases.compactMap { axis in
            guard let total = totals[axis], abs(total) >= AxisChange.threshold else { return nil }
            return MapDeltaRow(axis: axis, value: total)
        }
    }

    /// Magnify each axis's movement on the history radar, keeping the same scale across all its snapshots.
    var historyChartValues: [[Double]] {
        let measurements = snapshots.map { $0.map.chartValues }
        guard let latest = measurements.last else { return [] }

        let axes = latest.indices.map { axis in
            let values = measurements.map { $0[axis] }
            let baseline = latest[axis]
            let minimum = (values.min() ?? baseline) - baseline
            let maximum = (values.max() ?? baseline) - baseline
            let span = maximum - minimum
            let scale = span > 0.1 ? 1 / span : 10.0
            // Shift the whole axis if it hits an edge so distinct measurements never collapse there.
            let origin = min(max(baseline, -minimum * scale), 1 - maximum * scale)
            return values.map { origin + ($0 - baseline) * scale }
        }

        return measurements.indices.map { index in axes.map { $0[index] } }
    }
}
