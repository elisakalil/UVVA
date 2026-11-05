import Core
import DesignSystem
import SwiftUI

/// "Share your map" (QUIZ-R19, R20). Every action, "Not now" included, ends the Quiz (QUIZ-R25).
struct QuizShareView: View {
    var model: QuizShareUIModel
    var onFinish: () -> Void

    var body: some View {
        ShareScreen(title: String(localized: "Share your map", bundle: .module), message: model.message) { format in
            PalateShareCard(heading: model.heading, phrase: model.dominantPhrase,
                            chartValues: model.map.chartValues, chartLabels: PalateAxis.allCases.map(\.label),
                            strong: Set(model.highlighted.compactMap { PalateAxis.allCases.firstIndex(of: $0) }),
                            lines: [ShareCardLine(tag: String(localized: "Loves", bundle: .module), text: model.loves),
                                    ShareCardLine(tag: String(localized: "Never", bundle: .module), text: model.never)],
                            format: format)
        } onFinish: {
            onFinish()
        }
    }
}
