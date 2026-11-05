import DesignSystem
import SwiftUI

/// Find friends (ONB-R36). "Continue" asks for the contacts.
struct FindFriendsView<ViewModel: FindFriendsViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Text(viewModel.uiModel.findFriendsText.uppercased())
                    .font(UVVAFont.sans(9)).tracking(2.7).opacity(0.7)
                Text(viewModel.uiModel.addYourClosestFriendsToStartText)
                    .font(UVVAFont.sans(22, .ultraLight)).tracking(-0.2).lineSpacing(3)
                    .frame(maxWidth: 280).padding(.top, 18)
                viewModel.uiModel.illustration.resizable().scaledToFit().frame(width: 92, height: 128).padding(.top, 30)
                Text(viewModel.uiModel.uvvaIsBetterWithFriendsAddText)
                    .font(UVVAFont.sans(12)).lineSpacing(6).opacity(0.72)
                    .frame(maxWidth: 280).padding(.top, 30)
                ActionButton(viewModel.uiModel.continueText, isEnabled: !viewModel.uiModel.isAsking) {
                    Task { await viewModel.findFriends() }
                }
                .frame(width: 200)
                .padding(.top, 34)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 34)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: viewModel.uiModel.privacyIcon).font(.system(size: 10, weight: .light))
                Text(viewModel.uiModel.weWillNeverDoAnythingCreepyText)
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
