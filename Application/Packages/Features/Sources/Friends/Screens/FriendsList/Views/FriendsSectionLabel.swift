import DesignSystem
import SwiftUI

/// The title of a part of the tab: "QUICK ADD", "REQUESTS".
struct FriendsSectionLabel: View {
    var text: String

    var body: some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(11.5, .medium))
            .tracking(2.3)
            .opacity(0.9)
            .accessibilityAddTraits(.isHeader)
    }
}

/// The title of a card of a friend's Map (FRI-R11): "MARINA MAP", "WINES THAT MARINA WOULD LIKE", in the brush
/// lettering of the Home's cards.
struct FriendsCardTitle: View {
    var text: String

    var body: some View {
        Text(text.uppercased())
            .font(UVVAFont.redGrapes(17))
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}
