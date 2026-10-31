import Core
import CoreGraphics
import DesignSystem

extension PalateMapChart {
    init(map: PalateMap, strong: [PalateAxis], labelSize: CGFloat = 8, labelOpacity: Double = 0.7) {
        self.init(values: map.chartValues,
                  labels: PalateAxis.allCases.map(\.label),
                  strong: Set(strong.compactMap { PalateAxis.allCases.firstIndex(of: $0) }),
                  labelSize: labelSize,
                  labelOpacity: labelOpacity)
    }
}
