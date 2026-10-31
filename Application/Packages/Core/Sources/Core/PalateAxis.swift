import Foundation

/// The eight wine axes (QUIZ-R01).
/// `allCases` follows the canonical order of the chart, used to break ties (QUIZ-R02).
public enum PalateAxis: String, CaseIterable, Codable, CodingKeyRepresentable, Sendable {
    case floral, body, tannin, spice, oak, sweetness, acidity, fruit

    public var label: String { rawValue.capitalized }
}
