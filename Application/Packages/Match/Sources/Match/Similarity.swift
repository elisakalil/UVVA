import Core
import Foundation

public enum Similarity {
    /// Euclidean distance across the eight axes, same weight, scaled to 0...1 (QUIZ-R21).
    public static func between(_ a: PalateMap, _ b: PalateMap) -> Double {
        let squares = PalateAxis.allCases.map { pow(a[$0] - b[$0], 2) }
        let distance = squares.reduce(0, +).squareRoot()
        let maxDistance = PalateMap.range.upperBound * Double(PalateAxis.allCases.count).squareRoot()
        return 1 - distance / maxDistance
    }
}
