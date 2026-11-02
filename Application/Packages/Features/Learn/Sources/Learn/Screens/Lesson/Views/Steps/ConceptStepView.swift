import DesignSystem
import SwiftUI

/// LEARN-R15: a title, the text and, when there is one, the key idea.
struct ConceptStepView: View {
    var title: String
    var bodyText: String
    var highlight: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LessonEyebrow(text: String(localized: "Concept", bundle: .module))
            Text(title)
                .font(UVVAFont.sans(32, .ultraLight))
                .tracking(-1)
                .padding(.top, 16)
            Text(bodyText)
                .font(UVVAFont.sans(16))
                .lineSpacing(6)
                .padding(.top, 34)
            if let highlight, !highlight.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    LessonEyebrow(text: String(localized: "Key idea", bundle: .module))
                    Text(highlight)
                        .font(UVVAFont.redGrapes(24))
                        .lineSpacing(4)
                        .foregroundStyle(LessonPalette.accent)
                }
                .padding(.top, 44)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 20)
        .foregroundStyle(LessonPalette.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
