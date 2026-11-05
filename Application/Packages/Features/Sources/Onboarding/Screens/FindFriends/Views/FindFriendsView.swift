import DesignSystem
import SwiftUI

/// Find friends (ONB-R36). "Continue" asks for the contacts.
struct FindFriendsView: View {
    var viewModel: FindFriendsViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Text(String(localized: "Find friends", bundle: .module).uppercased())
                    .font(UVVAFont.sans(9)).tracking(2.7).opacity(0.7)
                Text("Add your closest friends to start comparing palates.", bundle: .module)
                    .font(UVVAFont.sans(22, .ultraLight)).tracking(-0.2).lineSpacing(3)
                    .frame(maxWidth: 280).padding(.top, 18)
                UVVAIllustration.grape(4).resizable().scaledToFit().frame(width: 92, height: 128).padding(.top, 30)
                Text("UVVA is better with friends. Add them now and, once they accept, you will see where your palates meet and what to open together.", bundle: .module)
                    .font(UVVAFont.sans(12)).lineSpacing(6).opacity(0.72)
                    .frame(maxWidth: 280).padding(.top, 30)
                ActionButton(String(localized: "Continue", bundle: .module), isEnabled: !viewModel.isAsking) {
                    Task { await viewModel.findFriends() }
                }
                .frame(width: 200)
                .padding(.top, 34)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 34)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "lock").font(.system(size: 10, weight: .light))
                Text("We will never do anything creepy like spam or auto-add your friends.", bundle: .module)
            }
            .font(UVVAFont.sans(10.5))
            .lineSpacing(5)
            .multilineTextAlignment(.center)
            .opacity(0.55)
            .frame(maxWidth: 300)
            .padding(.bottom, 16)
        }
    }
}
