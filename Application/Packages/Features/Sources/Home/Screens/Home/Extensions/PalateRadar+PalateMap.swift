import Match
import Core
import DesignSystem

extension PalateRadar {
    /// The radar of a palate map, axes in chart order (QUIZ-R01), by position on the ruler (QUIZ-R05).
    init(map: PalateMap, highlight: PalateAxis? = nil) {
        self.init(values: map.chartValues,
                  highlight: highlight.flatMap { PalateAxis.allCases.firstIndex(of: $0) },
                  highlightLabel: highlight?.localizedLabel)
    }
}
