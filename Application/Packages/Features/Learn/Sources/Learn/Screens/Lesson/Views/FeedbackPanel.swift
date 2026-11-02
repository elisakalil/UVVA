import DesignSystem
import SwiftUI

/// After "Check": "Correct" or "Not quite", the explanation, and "Continue" (LEARN-R17).
struct FeedbackPanel: View {
    var model: FeedbackUIModel
    /// "Close", after two backs in a row.
    var onClose: (() -> Void)?
    var onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(model.title.uppercased())
                .font(UVVAFont.sans(11))
                .tracking(2.2)
                .foregroundStyle(model.isCorrect ? LessonPalette.correct : LessonPalette.wrong)
            Text(model.text)
                .font(UVVAFont.sans(15))
                .lineSpacing(5)
                .foregroundStyle(LessonPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 10) {
                if let onClose {
                    LessonButton(title: String(localized: "Close", bundle: .module), style: .clear, showsArrow: false,
                                 action: onClose)
                }
                LessonButton(title: String(localized: "Continue", bundle: .module), action: onContinue)
            }
            .padding(.top, 10)
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 12)
        // No fill and no rule: the lesson's background runs on under it.
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
