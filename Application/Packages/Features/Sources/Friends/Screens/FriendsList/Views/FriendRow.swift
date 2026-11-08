import DesignSystem
import SwiftUI

/// A friend (FRI-R04): who, their palate in a line, and the compatibility.
struct FriendRow: View {
    var row: FriendRowUIModel
    /// Nil outside the choice of who comes (FRI-R18).
    var isSelected: Bool?
    var resources = FriendsResourcesUIModel()

    var body: some View {
        HStack(spacing: 12) {
            FriendsPersonLabel(name: row.name, signature: row.signature)
            Text(row.compatibilityText)
                .font(UVVAFont.sans(24, .ultraLight))
                .monospacedDigit()
            if let isSelected {
                Image(systemName: isSelected ? resources.selectedIcon : resources.unselectedIcon)
                    .font(.system(size: 22, weight: .light))
                    .opacity(isSelected ? 1 : 0.5)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected == true ? .isSelected : [])
    }
}
