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
                        .foregroundStyle(UVVAColor.cream.opacity(0.92))
                case let .hasMatch(friend):
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(resources.compatibility(friend.compatibility))
                            .font(UVVAFont.sans(46, .ultraLight))
                        Text(resources.friendMatch(friend.name))
                            .font(UVVAFont.sans(12.5))
                            .foregroundStyle(UVVAColor.cream84)
                    }
                    Text(resources.friendsCardOpenTableTitle).font(UVVAFont.sans(12)).foregroundStyle(UVVAColor.cream84)
                case .hasFriends:
                    Text(resources.friendsCardTableTitle)
                        .font(UVVAFont.redGrapes(21))
                        .textCase(.uppercase)
                        .foregroundStyle(UVVAColor.cream.opacity(0.92))
                    Text(resources.friendsCardPickFriendsTitle).font(UVVAFont.sans(12)).foregroundStyle(UVVAColor.cream84)
                }
            }
        }
    }
}
