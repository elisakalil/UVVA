import Core
import Foundation

/// The map "Draw the map" makes from the Quiz answers (QUIZ-R04a to R04c). The answers are only the starting
/// point: they are read on the ruler, settled among the real wines most like them, and held near what was answered,
/// so what the person leans toward stays. Loving floral still means a map that leans to the more floral wines.
public enum QuizMapBuilder {
    /// QUIZ-R04b: how many real wines the answers settle among, one per wine whatever its vintages.
    public static let neighborCount = 20
    /// How many of the closest wines to read before setting vintages aside: enough to keep `neighborCount` labels.
    public static let candidateCount = 120
    /// QUIZ-R04c: how far, in positions, an axis may settle from its answer.
    public static let soulBand = 1.5
    /// QUIZ-R04c: an answer this high stays above the middle of the wines…
    public static let highAnswer = 6
    public static let highFloor = 5.5
    /// …and one this low stays below it.
    public static let lowAnswer = 3
    public static let lowCeiling = 3.5

    /// QUIZ-R04a to R04c. With no wines to settle among (no catalog on the device yet), the answers read on the
    /// ruler.
    public static func map(_ answers: [PalateAxis: Int], among wines: [Wine]) -> PalateMap {
        let settled = settle(answers, among: wines)
        return PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { axis in
            let answer = answers[axis] ?? 0
            let position = WineRuler.position(of: settled[axis], on: axis)
            return (axis, WineRuler.value(atPosition: hold(position, near: answer), on: axis))
        }))
    }

    /// QUIZ-R04c: the position kept within `soulBand` of the answer, and on its side of the middle.
    static func hold(_ position: Double, near answer: Int) -> Double {
        var lower = Double(answer) - soulBand
        var upper = Double(answer) + soulBand
        if answer >= highAnswer { lower = max(lower, highFloor) }
        if answer <= lowAnswer { upper = min(upper, lowCeiling) }
        return min(max(position, lower), upper)
    }

    /// QUIZ-R04b: the closest wines by position, one per label, weighted by closeness, averaged on the ruler.
    static func settle(_ answers: [PalateAxis: Int], among wines: [Wine]) -> PalateMap {
        let target = PalateMap(answers.mapValues(Double.init))
        let scored: [(wine: Wine, distance: Double)] = wines.map { wine in
            (wine, Similarity.distance(WineRuler.positions(of: wine.profile), target))
        }
        let sorted = scored.sorted { lhs, rhs in
            lhs.distance == rhs.distance ? lhs.wine.id < rhs.wine.id : lhs.distance < rhs.distance
        }
        var labels = Set<String>()
        var neighbors: [(wine: Wine, weight: Double)] = []
        for item in sorted where neighbors.count < neighborCount && labels.insert(label(item.wine)).inserted {
            neighbors.append((item.wine, 1 / (item.distance + 0.5)))
        }
        guard !neighbors.isEmpty else { return WineRuler.map(answers) }
        let total = neighbors.reduce(0) { $0 + $1.weight }
        var values: [PalateAxis: Double] = [:]
        for axis in PalateAxis.allCases {
            values[axis] = neighbors.reduce(0) { $0 + $1.wine.profile[axis] * $1.weight } / total
        }
        return PalateMap(values)
    }

    /// One wine whatever its vintages.
    private static func label(_ wine: Wine) -> String {
        "\(wine.producer.lowercased())|\(wine.name.lowercased())"
    }
}
