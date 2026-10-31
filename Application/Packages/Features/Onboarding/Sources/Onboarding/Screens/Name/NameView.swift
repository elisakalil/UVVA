import DesignSystem
import SwiftUI

/// 01 / 02 · Name (ONB-R14 to R16).
struct NameView: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SignUpHeader(counter: "01 / 02", onBack: { viewModel.back() })
            SignUpTitle(title: String(localized: "And what should we call you?", bundle: .module),
                        detail: String(localized: "Your first name is enough. We took it from your account; change it if you like.", bundle: .module),
                        detailWidth: 265)
                .padding(.top, 56)

            TextField("", text: $viewModel.name, prompt: Text(verbatim: "Elisa").foregroundStyle(UVVAColor.creamFill.opacity(0.28)))
                .font(UVVAFont.sans(26))
                .tracking(-0.26)
                .textContentType(.givenName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.continue)
                .focused($focused)
                .onSubmit { viewModel.continueFromName() }
                .padding(.bottom, 13)
                .overlay(alignment: .bottom) { Rectangle().opacity(0.3).frame(height: 0.5) }
                .padding(.top, 44)

            Text((viewModel.nameIsValid ? String(localized: "Nice to meet you", bundle: .module)
                                        : String(localized: "At least two letters", bundle: .module)).uppercased())
                .font(UVVAFont.sans(9))
                .tracking(2.3)
                .opacity(0.35)
                .padding(.top, 16)
                .contentTransition(.opacity)

            Spacer(minLength: 20)
            ActionButton(String(localized: "Continue", bundle: .module), isEnabled: viewModel.nameIsValid,
                         action: viewModel.continueFromName)
        }
        .padding(.horizontal, 30)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .onAppear { focused = true }
    }
}
