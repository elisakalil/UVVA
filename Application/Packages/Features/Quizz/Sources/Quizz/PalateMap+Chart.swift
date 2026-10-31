import Core
import CoreGraphics
import DesignSystem

extension PalateMap {
    /// Values in chart order (QUIZ-R01), each 0...1, for `PalateMapChart`.
    var chartValues: [Double] { PalateAxis.allCases.map { self[$0] / PalateMap.range.upperBound } }
}

extension PalateMapChart {
    init(map: PalateMap, strong: [PalateAxis], labelSize: CGFloat = 8, labelOpacity: Double = 0.7) {
        self.init(values: map.chartValues,
                  labels: PalateAxis.allCases.map(\.label),
                  strong: Set(strong.compactMap { PalateAxis.allCases.firstIndex(of: $0) }),
                  labelSize: labelSize,
                  labelOpacity: labelOpacity)
    }
}
