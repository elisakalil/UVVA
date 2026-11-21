import DesignSystem
import SwiftUI

/// The avatar, the name and the palate signature, shared by every row of the tab.
struct FriendsPersonLabel: View {
    var name: String
    var signature: String

    var body: some View {
        HStack(spacing: 14) {
            FriendsAvatar(size: 38)
            VStack(alignment: .leading, spacing: 6) {
                Text(name).font(UVVAFont.sans(15)).opacity(0.94).lineLimit(1)
                Text(signature).font(UVVAFont.sans(9.5)).tracking(1.9).opacity(0.55).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The avatar of the tab: the app's default picture (friends have no photo yet), inside a thin cream ring.
struct FriendsAvatar: View {
    var size: CGFloat

    var body: some View {
        Avatar(photo: nil, size: size)
            .overlay(Circle().strokeBorder(UVVAColor.creamFill.opacity(0.45), lineWidth: 0.5))
    }
}
