import DesignSystem
import SwiftUI

/// The cream card under the readings (QUIZ-R17).
struct MapKeepsMovingCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "This map keeps moving", bundle: .module).uppercased())
                .font(UVVAFont.sans(9, .semibold))
                .tracking(3.2)
                .foregroundStyle(UVVAColor.mossDeep)
            Text("Every time you save a note on a wine you liked, UVVA recalculates your eight readings. The map you see here is your taste today, not a verdict.", bundle: .module)
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
