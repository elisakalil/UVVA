import Core
import Foundation

public enum Similarity {
    /// The distance at which a wine counts as nothing like the map: about 4 points apart on every axis. The
    /// theoretical maximum (9 × √8) is never reached by real wines and kept every match between 70% and 90%.
    public static let farDistance = 12.0

    /// Euclidean distance across the eight axes, same weight, scaled to 0...1 against `farDistance` (QUIZ-R21).
    public static func between(_ a: PalateMap, _ b: PalateMap) -> Double {
        let squares = PalateAxis.allCases.map { pow(a[$0] - b[$0], 2) }
        let distance = squares.reduce(0, +).squareRoot()
        return max(0, 1 - distance / farDistance)
    }
}
