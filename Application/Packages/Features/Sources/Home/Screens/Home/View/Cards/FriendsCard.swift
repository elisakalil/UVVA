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
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(resources.compatibility(compatibility))
                                .font(UVVAFont.sans(64, .ultraLight))
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                            Text(resources.friendMatch(name))
                                .font(UVVAFont.sans(12.5))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        Text(resources.friendsCardOpenTableTitle).font(UVVAFont.sans(12)).foregroundStyle(.white)
                    }
                    .frame(maxHeight: .infinity, alignment: .topLeading)
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
