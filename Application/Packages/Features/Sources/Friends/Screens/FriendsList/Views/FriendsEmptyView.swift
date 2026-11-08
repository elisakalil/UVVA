import DesignSystem
import SwiftUI

/// No friend and no request (FRI-R06, D2): the invite, above Quick add.
struct FriendsEmptyView: View {
    var resources: FriendsResourcesUIModel
    var canInvite: Bool
    var onInvite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(resources.emptyTitleText)
                .font(UVVAFont.sans(22, .ultraLight))
            Text(resources.emptyBodyText)
                .font(UVVAFont.sans(12.5)).lineSpacing(3).opacity(0.8)
                .fixedSize(horizontal: false, vertical: true)
            if canInvite {
                ActionButton(resources.inviteText, action: onInvite)
                    .padding(.top, 8)
            }
        }
        .padding(.vertical, 8)
    }
}
