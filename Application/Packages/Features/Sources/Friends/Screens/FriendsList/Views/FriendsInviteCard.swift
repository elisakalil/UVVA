import DesignSystem
import SwiftUI

/// In place of Quick add when no contact is left to add (FRI-R07b): the app's cream card, as the Cellar's banner.
/// It stays while choosing who comes (FRI-R18). Tapping it opens the contacts list of the Onboarding.
struct FriendsInviteCard: View {
    var text: String
    var action: () -> Void

    private let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(UVVAFont.sans(14))
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(UVVAColor.mossDeep)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 24)
                .padding(.horizontal, 22)
                .background(UVVAColor.creamFill, in: shape)
                .contentShape(shape)
        }
        .buttonStyle(.plain)
    }
}
