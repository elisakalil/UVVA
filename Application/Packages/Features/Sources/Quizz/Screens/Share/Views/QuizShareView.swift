import Core
import DesignSystem
import SwiftUI

/// "Share your map" (QUIZ-R19, R20). Every action, "Not now" included, ends the Quiz (QUIZ-R25).
struct QuizShareView: View {
    var resources = QuizResourcesUIModel()
    var model: QuizShareUIModel
    var onFinish: () -> Void

    var body: some View {
        ShareScreen(title: resources.shareYourMapText, message: model.message) { format in
            PalateShareCard(heading: model.heading, phrase: model.dominantPhrase,
                            chartValues: model.map.chartValues, chartLabels: PalateAxis.allCases.map(\.label),
                            strong: Set(model.highlighted.compactMap { PalateAxis.allCases.firstIndex(of: $0) }),
                            lines: [ShareCardLine(tag: resources.lovesText, text: model.loves),
                                    ShareCardLine(tag: resources.neverText, text: model.never)],
                            format: format)
        } onFinish: {
            onFinish()
        }
    }
}
