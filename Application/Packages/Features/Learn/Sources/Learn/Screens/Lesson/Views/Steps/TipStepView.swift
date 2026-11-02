import DesignSystem
import SwiftUI

/// LEARN-R15: the tip, wine on cream.
struct TipStepView: View {
    var bodyText: String

    var body: some View {
        Text(bodyText)
            .font(UVVAFont.redGrapes(24))
            .lineSpacing(5)
            .foregroundStyle(LessonPalette.wine)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, minHeight: 420, alignment: .leading)
    }
}
