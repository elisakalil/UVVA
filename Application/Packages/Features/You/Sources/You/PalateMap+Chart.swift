import Core
import Foundation

extension PalateMap {
    /// Values in chart order (QUIZ-R01), each 0...1, for `PalateMapChart`.
    var chartValues: [Double] { PalateAxis.allCases.map { self[$0] / PalateMap.range.upperBound } }
}
