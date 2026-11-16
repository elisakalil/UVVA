import Core
import Foundation

public enum Similarity {
    /// The distance at which a wine counts as nothing like the map: about 4.6 points apart on every axis of the
    /// ruler. Built maps sit among real wines (QUIZ-R04b), so the best wine is usually 1 to 3 points away (78% to 93%)
    /// and the far end of the catalog near 30%, never all at 0%.
    public static let farDistance = 13.0

    /// Euclidean distance across the eight axes of the ruler, same weight (QUIZ-R21).
    public static func distance(_ a: PalateMap, _ b: PalateMap) -> Double {
        PalateAxis.allCases.map { pow(a[$0] - b[$0], 2) }.reduce(0, +).squareRoot()
    }

    /// The distance as 0...1 (QUIZ-R21): `1 − distance / farDistance`, a straight line. No flat top, so two close
    /// wines still read apart (1 point 92%, 2 points 85%, 3 points 77%, 5 points 62%); 100% only for the map itself.
    public static func between(_ a: PalateMap, _ b: PalateMap) -> Double {
        max(0, 1 - distance(a, b) / farDistance)
    }

    /// The match as shown on screen, 0...100.
    public static func percent(_ a: PalateMap, _ b: PalateMap) -> Int {
        Int((between(a, b) * 100).rounded())
    }
}
