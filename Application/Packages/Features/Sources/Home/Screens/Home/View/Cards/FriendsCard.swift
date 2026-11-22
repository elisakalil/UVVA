import Core
import DesignSystem
import SwiftUI

struct FriendsCard: View {
    var resources = HomeResourcesUIModel()
    var state: HomeCardModel.FriendsCardState

    var body: some View {
        FrostedCard(padding: 24) {
            VStack(alignment: .leading, spacing: 14) {
                switch state {
                case .noFriends:
                    Text(resources.friendsCardInviteTitle)
                        .font(UVVAFont.redGrapes(17))
                        .textCase(.uppercase)
                        .lineSpacing(2)
                        .foregroundStyle(.white)
                case let .hasMatch(_, name, compatibility):
                    VStack(alignment: .leading, spacing: 0) {
                        // The number fills the card's width from its top, the sign small beside it so the digits
                        // can grow; it starts oversized and shrinks until it fits.
                        Text("\(Text(resources.compatibilityNumber(compatibility)))\(Text(resources.compatibilitySign).font(UVVAFont.sans(90, .ultraLight)))")
                            .font(UVVAFont.sans(200, .ultraLight))
                            .tracking(-2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.1)
                            .accessibilityLabel(resources.compatibility(compatibility))
                            // The top of the digits, not of the line, meets the card's padding.
                            .alignmentGuide(.top) { $0[.firstTextBaseline] * 0.26 }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        Text(resources.friendMatch(name))
                            .font(UVVAFont.sans(14))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                case .hasFriends:
                    Text(resources.friendsCardTableTitle)
                        .font(UVVAFont.redGrapes(24))
                        .textCase(.uppercase)
                        .lineSpacing(2)
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
            }
        }
    }
}
