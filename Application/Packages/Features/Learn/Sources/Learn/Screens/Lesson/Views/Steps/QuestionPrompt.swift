import DesignSystem
import SwiftUI

/// The eyebrow and the question, at the top of every question step.
struct QuestionPrompt: View {
    var eyebrow: String
    var prompt: String
    var hint: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LessonEyebrow(text: eyebrow)
            Text(prompt)
                .font(UVVAFont.sans(26, .ultraLight))
                .tracking(-0.6)
                .lineSpacing(3)
            if let hint {
                Text(hint).font(UVVAFont.sans(14)).foregroundStyle(LessonPalette.ink.opacity(0.72))
            }
        }
        .foregroundStyle(LessonPalette.ink)
        .padding(.horizontal, 24)
        .padding(.top, 6)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
