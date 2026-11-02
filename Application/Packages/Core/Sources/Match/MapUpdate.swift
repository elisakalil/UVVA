import Core

/// The map after a rating (QUIZ-R22): each axis moves by `weight × (wine − map)`, kept within 0...9.
public enum MapUpdate {
    /// The new map and every axis before and after, in the canonical order.
    public static func apply(_ verdict: Verdict, wine: PalateMap, to map: PalateMap) -> (map: PalateMap, changes: [AxisChange]) {
        let weight = RatingWeights.weight(for: verdict)
        var values: [PalateAxis: Double] = [:]
        var changes: [AxisChange] = []
        for axis in PalateAxis.allCases {
            let before = map[axis]
            let after = min(max(before + weight * (wine[axis] - before), PalateMap.range.lowerBound), PalateMap.range.upperBound)
            values[axis] = after
            changes.append(AxisChange(axis: axis, before: before, after: after))
        }
        return (PalateMap(values), changes)
    }
}
