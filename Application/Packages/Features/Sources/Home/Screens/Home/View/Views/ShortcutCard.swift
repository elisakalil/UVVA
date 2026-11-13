import DesignSystem
import SwiftUI

struct ShortcutCard: View {
    var eyebrow: String
    var title: String
    var subtitle: String
    var action: String
    var height: CGFloat? = nil

    var body: some View {
        FrostedCard(padding: 18) {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(text: eyebrow, color: .white)
                Text(title)
                    .font(UVVAFont.sans(17.5))
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
                Text(subtitle)
                    .font(UVVAFont.sans(12, .regular))
                    .foregroundStyle(.white)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                Spacer(minLength: 18)
                ActionLabel(text: action)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(minHeight: height.map { max(0, $0 - 36) }, alignment: .topLeading)
        }
    }
}
