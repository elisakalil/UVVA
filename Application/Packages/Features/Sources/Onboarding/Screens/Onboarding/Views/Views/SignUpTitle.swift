import DesignSystem
import SwiftUI

/// The question and its line of explanation on Name and Phone.
struct SignUpTitle: View {
    var title: String
    var detail: String
    var detailWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(UVVAFont.sans(30, .ultraLight))
                .tracking(-0.4)
                .lineSpacing(3)
                .frame(maxWidth: 290, alignment: .leading)
            Text(detail)
                .font(UVVAFont.sans(13))
                .lineSpacing(5)
                .opacity(0.55)
                .frame(maxWidth: detailWidth, alignment: .leading)
        }
    }
}
