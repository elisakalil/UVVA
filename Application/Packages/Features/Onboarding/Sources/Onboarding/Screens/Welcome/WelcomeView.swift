import DesignSystem
import SwiftUI

/// Welcome (ONB-R28 to R31, R38). Only Apple for now; Google comes later.
struct WelcomeView: View {
    var viewModel: OnboardingViewModel
    @State private var appeared = false

    private var canSignIn: Bool { viewModel.iCloudAvailable == true && !viewModel.isSigningIn }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("UVVA")
                .font(UVVAFont.whiteGrape(36))
                .tracking(2.9)
                .foregroundStyle(Color(hex: 0xF7F0E2))
                .frame(height: 42)
                .offset(y: appeared ? 0 : 10)
                .opacity(appeared ? 1 : 0)
            Text("Welcome. Let's find the wines you'll love.", bundle: .module)
                .font(UVVAFont.sans(30, .ultraLight))
                .tracking(-0.4)
                .lineSpacing(3)
                .frame(maxWidth: 300, alignment: .leading)
                .padding(.top, 32)
                .offset(x: appeared ? 0 : -30)
                .opacity(appeared ? 1 : 0)

            Spacer(minLength: 20)

            VStack(spacing: 18) {
                if viewModel.iCloudAvailable == false {
                    Text("UVVA keeps your account in iCloud. Sign in to iCloud in Settings, then come back.", bundle: .module)
                        .font(UVVAFont.sans(12))
                        .lineSpacing(4)
                        .multilineTextAlignment(.center)
                        .opacity(0.8)
                }
                if let notice = viewModel.notice {
                    Text(notice).font(UVVAFont.sans(12)).multilineTextAlignment(.center).opacity(0.8)
                }
                LegalAgreement(onOpen: { tab in withAnimation(.smooth) { viewModel.openLegal(tab) } })
                AppleButton(isEnabled: canSignIn) { Task { await viewModel.signIn() } }
            }
            .frame(maxWidth: .infinity)
            .offset(y: appeared ? 0 : 14)
            .opacity(appeared ? 1 : 0)
        }
        .padding(.horizontal, 30)
        .padding(.top, 50)
        .padding(.bottom, 24)
        .onAppear { withAnimation(.easeOut(duration: 0.8).delay(0.1)) { appeared = true } }
    }
}
