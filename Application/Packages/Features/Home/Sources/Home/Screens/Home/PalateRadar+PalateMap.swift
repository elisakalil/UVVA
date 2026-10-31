import Core
import DesignSystem

extension PalateRadar {
    /// The radar of a palate map, axes in chart order (QUIZ-R01).
    init(map: PalateMap, highlight: PalateAxis? = nil) {
        self.init(values: PalateAxis.allCases.map { map[$0] / PalateMap.range.upperBound },
                  highlight: highlight.flatMap { PalateAxis.allCases.firstIndex(of: $0) },
                  highlightLabel: highlight?.label)
    }
}
