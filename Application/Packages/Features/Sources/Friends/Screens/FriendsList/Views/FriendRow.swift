import DesignSystem
import SwiftUI

/// A friend (FRI-R04): who, their palate in a line, the compatibility and the way into their profile.
/// While choosing who comes (FRI-R18), a circle on the left takes the place of the compatibility and the chevron.
struct FriendRow: View {
    var row: FriendRowUIModel
    /// Nil outside the choice of who comes (FRI-R18).
    var isSelected: Bool?

    var body: some View {
        HStack(spacing: 14) {
            if let isSelected {
                Circle()
                    .fill(UVVAColor.creamFill.opacity(isSelected ? 1 : 0))
                    .overlay(Circle().strokeBorder(UVVAColor.creamFill.opacity(isSelected ? 1 : 0.45), lineWidth: 0.5))
                    .frame(width: 22, height: 22)
                    .animation(.easeOut(duration: 0.18), value: isSelected)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
            FriendsPersonLabel(name: row.name, signature: row.signature)
            if isSelected == nil {
                Text(row.compatibilityText)
                    .font(UVVAFont.sans(9))
                    .tracking(1.6)
                    .monospacedDigit()
                    .opacity(0.45)
                Text(verbatim: "›")
                    .font(UVVAFont.sans(20, .ultraLight))
                    .opacity(0.4)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 15)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected == true ? .isSelected : [])
    }
}
