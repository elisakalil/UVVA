import DesignSystem
import SwiftUI

/// The cream card under the readings (QUIZ-R17).
struct MapKeepsMovingCard: View {
    var resources = QuizResourcesUIModel()
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(resources.thisMapKeepsMovingText.uppercased())
                .font(UVVAFont.sans(9, .semibold))
                .tracking(3.2)
                .foregroundStyle(UVVAColor.mossDeep)
            Text(resources.everyTimeYouSaveAText)
                .font(UVVAFont.sans(13.5))
                .lineSpacing(5)
                .foregroundStyle(UVVAColor.mossDeep.opacity(0.82))
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: UVVARadius.card, style: .continuous).fill(UVVAColor.creamFill))
        .shadow(color: Color(hex: 0x080C06).opacity(0.18), radius: 21, y: 18)
    }
}
