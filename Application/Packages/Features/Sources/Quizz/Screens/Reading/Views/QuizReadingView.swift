import DesignSystem
import SwiftUI

/// One reading: the question, the answer word and the bar of ten positions (QUIZ-R07 to R13).
struct QuizReadingView: View {
    var resources = QuizResourcesUIModel()
    var model: QuizReadingUIModel
    var onSelect: (Int) -> Void
    var onChangeQuestion: () -> Void
    var onNext: () -> Void
    var onBack: () -> Void

    var body: some View {
        ZStack {
            QuizBackground(photoOpacity: 1, shade: [0.35, 0.55])
            VStack(alignment: .leading, spacing: 0) {
                FlowTopBar(caption: model.counter, onBack: onBack)
                ReadingProgress(resources: resources, count: model.count, current: model.index)
                    .padding(.top, 22)

                Text(model.prompt)
                    .font(UVVAFont.sans(24, .ultraLight))
                    .tracking(-0.36)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
                    .padding(.top, 36)
                    .id("prompt-\(model.index)-\(model.prompt)")
                    .transition(.opacity)

                Spacer(minLength: 16)

                HStack(alignment: .lastTextBaseline, spacing: 12) {
                    Text(model.answer ?? " ")
                        .font(UVVAFont.sans(40, .ultraLight))
                        .tracking(-1.2)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentTransition(.opacity)
                    Text(model.axisName.uppercased())
                        .font(UVVAFont.sans(11))
                        .tracking(3)
                        .opacity(0.5)
                }
                .frame(height: 112, alignment: .bottom)

                ReadingBar(resources: resources, selection: model.selection, onSelect: onSelect)
                    .padding(.top, 26)

                Spacer(minLength: 24)

                ActionButton(resources.changeQuestionText, style: .outline,
                             action: onChangeQuestion)
                ActionButton(model.button, isEnabled: model.canAdvance, action: onNext)
                    .padding(.top, 10)
                Text(model.footnote)
                    .font(UVVAFont.sans(10))
                    .tracking(0.6)
                    .opacity(0.42)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 18)
            }
            .padding(.horizontal, 26)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
    }
}
