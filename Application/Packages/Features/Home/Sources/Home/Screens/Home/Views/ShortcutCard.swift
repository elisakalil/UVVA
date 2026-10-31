import DesignSystem
import SwiftUI

struct ShortcutCard: View {
    var eyebrow: String
    var title: String
    var subtitle: String
    var action: String

    var body: some View {
        FrostedCard(padding: 18) {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(text: eyebrow)
                Text(title).font(UVVAFont.sans(17.5)).padding(.top, 12)
                Text(subtitle).font(UVVAFont.sans(12, .regular)).foregroundStyle(UVVAColor.cream84).padding(.top, 8)
                ActionLabel(text: action).padding(.top, 18)
            }
        }
    }
}
