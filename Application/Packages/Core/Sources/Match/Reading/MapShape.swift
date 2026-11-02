import Core
import Foundation

/// Whether a value reads as low, in the middle or high (QUIZ-R14a). Measured on the displayed level, so the texts
/// always agree with the pips: 5 is the middle, neither high nor low.
public enum AxisTone: Sendable {
    case low, neutral, high

    public static let middle = 5

    public init(_ value: Double) {
        let level = MapReading.level(value)
        self = level < Self.middle ? .low : level > Self.middle ? .high : .neutral
    }
}

/// The shapes of map that a single strongest and a single quietest axis cannot describe (QUIZ-R14a).
public enum MapShape: Equatable, Sendable {
    /// The eight axes on the same level.
    case flat(AxisTone)
    /// Seven axes on one level and the other one under them.
    case allButOneLower(PalateAxis)
    /// Seven axes on one level and the other one over them.
    case allButOneHigher(PalateAxis)
    /// Anything else.
    case shaped
}
