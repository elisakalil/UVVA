import DesignSystem
import SwiftUI

/// A request to the user (FRI-R08a): Accept and Decline.
struct FriendRequestRow: View {
    var resources: FriendsResourcesUIModel
    var row: FriendRequestRowUIModel
    var onAccept: () -> Void
    var onDecline: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FriendsPersonLabel(name: row.name, signature: row.signature)
            HStack(spacing: 8) {
                FriendsPillButton(title: resources.acceptText, isSolid: true, action: onAccept)
                FriendsPillButton(title: resources.declineText, isSolid: false, action: onDecline)
            }
            .padding(.leading, 53)
        }
        .padding(.vertical, 14)
    }
}
