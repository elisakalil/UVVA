import SwiftUI

/// "LOVES  Elisa drinks for…" on the share card. Compact on the Story, where the map takes the room.
struct ShareLine: View {
    var tag: String
    var text: String
    var isFirst: Bool
    var compact = false

    var body: some View {
        VStack(spacing: 0) {
            if !isFirst { Rectangle().opacity(0.16).frame(height: 1) }
            HStack(alignment: .firstTextBaseline, spacing: compact ? 8 : 12) {
                Text(tag.uppercased())
                    .font(UVVAFont.sans(compact ? 5.5 : 7))
                    .tracking(compact ? 1.2 : 1.5)
                    .opacity(0.55)
                    .frame(width: compact ? 40 : 54, alignment: .leading)
                Text(text)
                    .font(UVVAFont.sans(compact ? 7.5 : 9.5))
                    .lineSpacing(compact ? 1 : 2)
                    .opacity(0.88)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, isFirst ? 0 : (compact ? 5 : 9))
            .padding(.bottom, compact ? 5 : 9)
        }
    }
}
