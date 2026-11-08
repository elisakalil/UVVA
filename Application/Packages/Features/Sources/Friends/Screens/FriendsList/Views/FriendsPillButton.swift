import DesignSystem
import SwiftUI

/// The small button of a row: outline while waiting for the tap, solid cream once done or for the main choice.
struct FriendsPillButton: View {
    var title: String
    var isSolid: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(UVVAFont.sans(9, .semibold))
                .tracking(2.2)
                .foregroundStyle(isSolid ? UVVAColor.mossDeep : UVVAColor.creamFill)
                .padding(.horizontal, 12)
                .frame(minWidth: 70, minHeight: 44)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(UVVAColor.creamFill.opacity(isSolid ? 1 : 0))
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(UVVAColor.creamFill.opacity(isSolid ? 0 : 0.45), lineWidth: 0.5))
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.3), value: isSolid)
    }
}
