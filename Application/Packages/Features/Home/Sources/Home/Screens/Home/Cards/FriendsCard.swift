import Core
import DesignSystem
import SwiftUI

struct FriendsCard: View {
    var variant: HomeCard.FriendsVariant

    var body: some View {
        FrostedCard(padding: 24) {
            VStack(alignment: .leading, spacing: 14) {
                switch variant {
                case .invite:
                    Text("Invite friends to discover their palate and find a wine you'll both love")
                        .font(UVVAFont.redGrapes(17))
                        .textCase(.uppercase)
                        .lineSpacing(2)
                        .foregroundStyle(UVVAColor.cream.opacity(0.92))
                case let .match(friend):
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(friend.compatibility)%")
                            .font(UVVAFont.sans(46, .ultraLight))
                        Text("match with \(friend.name)")
                            .font(UVVAFont.sans(12.5))
                            .foregroundStyle(UVVAColor.cream84)
                    }
                    Text("Open the table →").font(UVVAFont.sans(12)).foregroundStyle(UVVAColor.cream84)
                case .setTable:
                    Text("Set a table with your friends")
                        .font(UVVAFont.redGrapes(21))
                        .textCase(.uppercase)
                        .foregroundStyle(UVVAColor.cream.opacity(0.92))
                    Text("Pick who is coming →").font(UVVAFont.sans(12)).foregroundStyle(UVVAColor.cream84)
                }
            }
        }
    }
}
