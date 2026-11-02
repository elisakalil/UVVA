import DesignSystem
import SwiftUI

/// The question, at the top of every question step.
struct QuestionPrompt: View {
    var prompt: String
    var hint: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
