import DesignSystem
import SwiftUI

/// Welcome (ONB-R28 to R31, R38). Apple signs in; the Google button is there but not wired yet.
struct WelcomeView<ViewModel: WelcomeViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @State private var appeared = false

    private var canSignIn: Bool { viewModel.uiModel.canSignIn }

    /// How far the logo and the greeting sit below the top of the safe area.
    static var headerTop: CGFloat { 130 }
    /// Where the fade-in starts. Never fully hidden: it runs while the Splash fades out, and from 0 the page
    /// read as empty between the two.
    static var hiddenOpacity: Double { 0.3 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(viewModel.uiModel.uvvaText)
                .font(UVVAFont.whiteGrape(28))
                .tracking(2.25)
                .foregroundStyle(Color(hex: 0xF7F0E2))
                .frame(height: 33)
                .offset(y: appeared ? 0 : 10)
                .opacity(appeared ? 1 : Self.hiddenOpacity)
            Text(viewModel.uiModel.welcomeLetSFindTheWinesText)
                .font(UVVAFont.sans(36, .ultraLight))
                .tracking(-0.4)
                .lineSpacing(3)
                .frame(maxWidth: 340, alignment: .leading)
                .padding(.top, 32)
                .offset(x: appeared ? 0 : -30)
                .opacity(appeared ? 1 : Self.hiddenOpacity)

            Spacer(minLength: 20)

            VStack(spacing: 18) {
                if viewModel.uiModel.iCloudAvailable == false {
                    Text(viewModel.uiModel.toContinueWithAppleSignInText)
                        .font(UVVAFont.sans(12))
                        .lineSpacing(4)
                        .multilineTextAlignment(.center)
                        .opacity(0.8)
                }
                if let notice = viewModel.uiModel.notice {
                    Text(notice).font(UVVAFont.sans(12)).multilineTextAlignment(.center).opacity(0.8)
                }
                LegalAgreement(uiModel: viewModel.uiModel.agreement, onOpen: { tab in withAnimation(.smooth) { viewModel.openLegal(tab) } })
                VStack(spacing: 10) {
                    AppleButton(uiModel: viewModel.uiModel.appleButton, isEnabled: canSignIn) { Task { await viewModel.signIn() } }
                    GoogleButton(uiModel: viewModel.uiModel.googleButton, isEnabled: !viewModel.uiModel.isSigningIn) {}
                }
            }
            .frame(maxWidth: .infinity)
            .offset(y: appeared ? 0 : 14)
            .opacity(appeared ? 1 : Self.hiddenOpacity)
        }
        .padding(.horizontal, 30)
        .padding(.top, Self.headerTop)
        .padding(.bottom, 24)
        .onAppear { withAnimation(.smooth) { appeared = true } }
    }
}
