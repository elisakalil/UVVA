import Foundation

/// Intensity 0...9 per axis (QUIZ-R04).
public struct PalateMap: Equatable, Sendable {
    public static let range: ClosedRange<Double> = 0...9

    public private(set) var values: [PalateAxis: Double]

    public init(_ values: [PalateAxis: Double]) {
        var clamped: [PalateAxis: Double] = [:]
        for axis in PalateAxis.allCases {
            clamped[axis] = min(max(values[axis] ?? 0, Self.range.lowerBound), Self.range.upperBound)
        }
        self.values = clamped
    }

    public subscript(axis: PalateAxis) -> Double { values[axis] ?? 0 }

    /// Axes by value, descending; ties follow the canonical order (QUIZ-R14).
    public var ranked: [PalateAxis] {
        PalateAxis.allCases.enumerated()
            .sorted { lhs, rhs in
                let (l, r) = (self[lhs.element], self[rhs.element])
                return l == r ? lhs.offset < rhs.offset : l > r
            }
            .map(\.element)
    }

    /// The top three axes, upper-cased and joined by " · " (FRI-R04, YOU-R01).
    public var signature: String {
        ranked.prefix(3).map { $0.label.uppercased() }.joined(separator: " · ")
    }
}
