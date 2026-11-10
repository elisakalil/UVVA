import DesignSystem
import SwiftUI

/// After "Check": "Correct" or "Not quite", the explanation, and "Continue" (LEARN-R17).
struct FeedbackPanel: View {
    var resources = LearnResourcesUIModel()
    var model: FeedbackUIModel
    var onContinue: () -> Void
    /// The title first, then the explanation, then "Continue", so the answer arrives with calm.
    @State private var isShown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(model.title.uppercased())
                .font(UVVAFont.sans(11))
                .tracking(2.2)
                .foregroundStyle(model.isCorrect ? LessonPalette.correct : LessonPalette.wrong)
                .lessonRise(isShown)
            Text(model.text)
                .font(UVVAFont.sans(15))
                .lineSpacing(5)
                .foregroundStyle(LessonPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .lessonRise(isShown, delay: 0.08)
            LessonButton(title: resources.continueText, action: onContinue)
                .padding(.top, 10)
                .lessonRise(isShown, delay: 0.16)
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 12)
        // No fill and no rule: the lesson's background runs on under it.
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { isShown = true }
    }
}
