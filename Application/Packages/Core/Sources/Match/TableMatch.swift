import Core
import Foundation

/// User × user (MATCH.md): compatibility between maps and the tables of FRI §6. Every map at the table counts the
/// same, the user's included.
public enum TableMatch {
    /// An axis is shared when everyone is at least this high on it…
    public static let sharedMinimum = 5.5
    /// …and the lowest and highest readings are at most this far apart.
    public static let sharedMaxGap = 1.5
    /// At most this many shared axes are named (FRI §3).
    public static let sharedLimit = 3
    /// The upper gap of each `AxisSpread`; above `someGive` it is `widest`.
    public static let spreadLimits: [(AxisSpread, Double)] = [(.same, 0.5), (.closest, 1.5), (.someGive, 3)]

    /// FRI-R04, R12, HOME-R11: the same distance as user × wine (QUIZ-R21), 0...100.
    public static func compatibility(_ a: PalateMap, _ b: PalateMap) -> Int {
        Similarity.percent(a, b)
    }

    /// FRI-R19: the average compatibility of every pair at the table, 0...100. A table of two is the pair's.
    public static func tableCompatibility(_ maps: [PalateMap]) -> Int {
        var scores: [Double] = []
        for i in maps.indices {
            for j in maps.indices where j > i { scores.append(Similarity.between(maps[i], maps[j])) }
        }
        guard !scores.isEmpty else { return 100 }
        return Int((scores.reduce(0, +) / Double(scores.count) * 100).rounded())
    }

    /// Every map crossed into one: the average of each axis ("Where the table lands", FRI-R19).
    public static func crossed(_ maps: [PalateMap]) -> PalateMap {
        guard !maps.isEmpty else { return PalateMap([:]) }
        return PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { axis in
            (axis, maps.map { $0[axis] }.reduce(0, +) / Double(maps.count))
        }))
    }

    /// The highest reading of each axis ("The boldest reading", FRI-R19).
    public static func boldest(_ maps: [PalateMap]) -> PalateMap {
        PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { axis in
            (axis, maps.map { $0[axis] }.max() ?? 0)
        }))
    }

    /// From the lowest to the highest reading of an axis at the table.
    public static func range(_ maps: [PalateMap], _ axis: PalateAxis) -> ClosedRange<Double> {
        let values = maps.map { $0[axis] }
        return (values.min() ?? 0)...(values.max() ?? 0)
    }

    /// FRI-R12, R19: the axes everyone wants, by the table's average, at most `sharedLimit`.
    public static func sharedAxes(_ maps: [PalateMap]) -> [PalateAxis] {
        guard !maps.isEmpty else { return [] }
        let average = crossed(maps)
        return average.ranked
            .filter { axis in
                let range = range(maps, axis)
                return range.lowerBound >= sharedMinimum && range.upperBound - range.lowerBound <= sharedMaxGap
            }
            .prefix(sharedLimit)
            .map { $0 }
    }

    /// FRI-R19: Same, Closest, Some give or Widest, from the gap on the axis.
    public static func axisSpread(_ maps: [PalateMap], _ axis: PalateAxis) -> AxisSpread {
        let range = range(maps, axis)
        let gap = range.upperBound - range.lowerBound
        return spreadLimits.first { gap <= $0.1 + 1e-9 }?.0 ?? .widest
    }

    /// FRI-R14, R15: one bottle per course, Starter, Main and Dessert. For each course, the dish is the recipe
    /// closest to the crossed map, and the wine is the one, of a type the dish goes with, closest to the dish and the
    /// table together. A wine is used once. A course with no recipe, or no wine of its types, is left out.
    public static func tableBottles(_ maps: [PalateMap], wines: [Wine], recipes: [Recipe]) -> [TableBottle] {
        let table = crossed(maps)
        let shared = sharedAxes(maps)
        let candidates = shared.isEmpty ? Array(table.ranked.prefix(sharedLimit)) : shared
        var used = Set<String>()
        var bottles: [TableBottle] = []

        for course in TableCourse.allCases {
            let ranked = recipes.filter { $0.course == course.rawValue }
                .sorted { Similarity.between($0.profile, table) > Similarity.between($1.profile, table) }
            for recipe in ranked {
                let types = Set(recipe.wineTypes.map { $0.lowercased() })
                let target = Pairing.crossed(table, recipe.profile)
                let wine = wines
                    .filter { types.contains($0.type.lowercased()) && !used.contains($0.id) }
                    .max { Similarity.between($0.profile, target) < Similarity.between($1.profile, target) }
                guard let wine else { continue }
                used.insert(wine.id)
                let axis = candidates.max { wine.profile[$0] < wine.profile[$1] } ?? table.ranked[0]
                bottles.append(TableBottle(course: course, wine: wine, recipe: recipe, axis: axis))
                break
            }
        }
        return bottles
    }
}
