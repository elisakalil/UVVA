import Foundation

/// The eight wine axes (QUIZ-R01).
/// `allCases` follows the canonical order of the chart, used to break ties (QUIZ-R02).
enum Axis: String, CaseIterable, Sendable {
    case floral, body, tannin, spice, oak, sweetness, acidity, fruit

    var label: String { rawValue.capitalized }
}

/// Intensity 0...9 per axis (QUIZ-R04).
struct PalateMap: Equatable, Sendable {
    static let range: ClosedRange<Double> = 0...9

    private(set) var values: [Axis: Double]

    init(_ values: [Axis: Double]) {
        var clamped: [Axis: Double] = [:]
        for axis in Axis.allCases {
            clamped[axis] = min(max(values[axis] ?? 0, Self.range.lowerBound), Self.range.upperBound)
        }
        self.values = clamped
    }

    subscript(axis: Axis) -> Double { values[axis] ?? 0 }

    /// Axes by value, descending; ties follow the canonical order (QUIZ-R14).
    var ranked: [Axis] {
        Axis.allCases.enumerated()
            .sorted { lhs, rhs in
                let (l, r) = (self[lhs.element], self[rhs.element])
                return l == r ? lhs.offset < rhs.offset : l > r
            }
            .map(\.element)
    }

    /// The top three axes, upper-cased and joined by " · " (FRI-R04, YOU-R01).
    var signature: String {
        ranked.prefix(3).map { $0.label.uppercased() }.joined(separator: " · ")
    }
}

enum Similarity {
    /// Euclidean distance across the eight axes, same weight, scaled to 0...1 (QUIZ-R21).
    static func between(_ a: PalateMap, _ b: PalateMap) -> Double {
        let squares = Axis.allCases.map { pow(a[$0] - b[$0], 2) }
        let distance = squares.reduce(0, +).squareRoot()
        let maxDistance = PalateMap.range.upperBound * Double(Axis.allCases.count).squareRoot()
        return 1 - distance / maxDistance
    }
}
