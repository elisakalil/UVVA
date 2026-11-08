import DesignSystem
import SwiftUI

/// The avatar, the name and the palate signature, shared by every row of the tab.
struct FriendsPersonLabel: View {
    var name: String
    var signature: String

    var body: some View {
        HStack(spacing: 13) {
            Avatar(photo: nil, size: 40)
            VStack(alignment: .leading, spacing: 5) {
                Text(name).font(UVVAFont.sans(14)).lineLimit(1)
                Text(signature).font(UVVAFont.sans(9.5)).tracking(1.2).opacity(0.62).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}
