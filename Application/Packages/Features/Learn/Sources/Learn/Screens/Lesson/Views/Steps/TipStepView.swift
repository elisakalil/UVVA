import DesignSystem
import SwiftUI

/// LEARN-R15: "Uvva tip", wine on cream.
struct TipStepView: View {
    var bodyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            LessonEyebrow(text: String(localized: "Uvva tip", bundle: .module), color: LessonPalette.wine.opacity(0.7))
            Text(bodyText)
                .font(UVVAFont.redGrapes(24))
                .lineSpacing(5)
                .foregroundStyle(LessonPalette.wine)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, minHeight: 420, alignment: .leading)
    }
}
