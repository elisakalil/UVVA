import DesignSystem
import SwiftUI

/// "LOVES  Elisa drinks for…" on the share card.
struct ShareLine: View {
    var tag: String
    var text: String
    var isFirst: Bool

    var body: some View {
        VStack(spacing: 0) {
            if !isFirst { Rectangle().opacity(0.16).frame(height: 1) }
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(tag.uppercased())
                    .font(UVVAFont.sans(7))
                    .tracking(1.5)
                    .opacity(0.55)
                    .frame(width: 54, alignment: .leading)
                Text(text)
                    .font(UVVAFont.sans(9.5))
                    .lineSpacing(2)
                    .opacity(0.88)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, isFirst ? 0 : 9)
            .padding(.bottom, 9)
        }
    }
}
