#if os(iOS)
import DesignSystem
import SwiftUI

/// The top of the list's screens: a chevron back, and a caption on the right ("8 WINES ON THE LIST").
struct WineListTopBar: View {
    var caption: String
    var backText: String
    var onBack: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .light))
                    .frame(width: 44, height: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(backText)
            Spacer(minLength: 12)
            Text(caption.uppercased())
                .font(UVVAFont.sans(9.5))
                .tracking(1.9)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(UVVAColor.creamFill.opacity(0.8))
        }
        .foregroundStyle(UVVAColor.creamFill)
    }
}
#endif
