import Foundation

/// The one ruler of every palate map, the user's and the wines' (QUIZ-R04a, MATCH.md): how much of each axis a wine
/// has, 0...9. It is fixed, written once and never recalculated from the catalog, so a wine mapped tomorrow and a map
/// drawn today stand on the same scale however the catalog grows.
///
/// Maps are kept and compared on the ruler (the match, the ratings). They are shown by their position on it: the
/// Quiz answer that would land there, 0...9. A Quiz answer of 8 on floral is a wine more floral than most, 4.5 on
/// the ruler, and reads 8 again on screen.
public enum WineRuler {
    /// Kept with every Quiz map, so a map drawn on an older ruler can be drawn again from its answers.
    public static let version = 1

    /// The ruler value of each Quiz answer, 0...9, per axis. Rising, so every value has one position; only the bottom
    /// of sweetness is flat: most wines are dry, and a sweet tooth for food only reaches a sweet wine when it runs high.
    public static let table: [PalateAxis: [Double]] = [
        .floral: [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.5, 7.0],
        .body: [2.0, 3.5, 4.5, 5.0, 5.5, 6.0, 6.5, 7.0, 7.5, 8.5],
        .tannin: [0.0, 0.5, 1.0, 2.0, 4.0, 5.0, 6.0, 6.5, 7.0, 8.5],
        .spice: [0.5, 1.0, 2.0, 2.5, 3.0, 3.5, 4.0, 5.0, 6.0, 7.0],
        .oak: [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.5, 5.5, 7.0],
        .sweetness: [1.0, 1.0, 1.0, 1.0, 1.5, 2.0, 3.0, 5.0, 7.0, 8.5],
        .acidity: [3.5, 4.5, 5.0, 5.5, 6.0, 6.5, 7.0, 7.5, 8.0, 9.0],
        .fruit: [3.0, 4.5, 5.0, 5.5, 6.0, 6.5, 7.0, 7.5, 8.0, 9.0]
    ]

    public static let positions = 0...9

    /// The ruler value of a Quiz answer.
    public static func value(of answer: Int, on axis: PalateAxis) -> Double {
        steps(axis)[min(max(answer, positions.lowerBound), positions.upperBound)]
    }

    /// The ruler value at a position: a straight line between the anchors (`anchors`).
    public static func value(atPosition position: Double, on axis: PalateAxis) -> Double {
        let points = anchors(axis)
        guard let first = points.first, let last = points.last else { return 0 }
        if position <= first.position { return first.value }
        if position >= last.position { return last.value }
        let upper = points.firstIndex { $0.position >= position } ?? points.count - 1
        let (a, b) = (points[upper - 1], points[upper])
        return a.value + (b.value - a.value) * (position - a.position) / (b.position - a.position)
    }

    /// The position of a ruler value, 0...9: the answer that would land there, a straight line between the anchors.
    /// A dry wine (sweetness 1.0, the answers 0 to 3) reads 1.5, low, so those answers keep their order against
    /// the other axes instead of all falling to 0. Under the first anchor it reads 0 (bone dry), over the last 9.
    public static func position(of value: Double, on axis: PalateAxis) -> Double {
        let points = anchors(axis)
        guard let first = points.first, let last = points.last else { return 0 }
        if abs(value - first.value) < 1e-9 { return first.position }
        if value < first.value { return 0 }
        if value >= last.value { return abs(value - last.value) < 1e-9 ? last.position : Double(positions.upperBound) }
        let upper = points.firstIndex { $0.value > value } ?? points.count - 1
        let (a, b) = (points[upper - 1], points[upper])
        return a.position + (b.position - a.position) * (value - a.value) / (b.value - a.value)
    }

    /// One point per distinct value of the table, at the middle of the answers that share it: every answer on most
    /// axes, and 1.5 for the dry bottom of sweetness (answers 0 to 3).
    private static func anchors(_ axis: PalateAxis) -> [(position: Double, value: Double)] {
        let steps = steps(axis)
        var points: [(position: Double, value: Double)] = []
        var start = 0
        for index in steps.indices where index == steps.count - 1 || steps[index + 1] != steps[index] {
            points.append((Double(start + index) / 2, steps[index]))
            start = index + 1
        }
        return points
    }

    /// The Quiz answers read on the ruler, before they are settled among real wines (QUIZ-R04a).
    public static func map(_ answers: [PalateAxis: Int]) -> PalateMap {
        PalateMap(Dictionary(uniqueKeysWithValues: answers.map { ($0.key, value(of: $0.value, on: $0.key)) }))
    }

    /// Every axis of a map by its position: what the screen shows (QUIZ-R05).
    public static func positions(of map: PalateMap) -> PalateMap {
        PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, position(of: map[$0], on: $0)) }))
    }

    private static func steps(_ axis: PalateAxis) -> [Double] { table[axis] ?? Array(repeating: 0, count: 10) }
}
