import DesignSystem
import SwiftUI

/// 01 / 02 · Name (ONB-R14 to R16).
struct NameView: View {
    @Bindable var viewModel: NameViewModel
    @FocusState private var focused: Bool
    @State private var leaving = false

    /// About how long the system keyboard takes to slide away.
    static let keyboardHide: Duration = .milliseconds(250)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SignUpHeader(counter: "01 / 02", onBack: { viewModel.back() })
            SignUpTitle(title: String(localized: "And what should we call you?", bundle: .module),
                        detail: String(localized: "Your first name is enough.", bundle: .module),
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
                .onSubmit(next)
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
            ActionButton(String(localized: "Continue", bundle: .module), isEnabled: viewModel.nameIsValid && !leaving,
                         action: next)
        }
        .padding(.horizontal, 30)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .onAppear { focused = true }
    }

    /// The Phone step has its own keypad, so the system keyboard is put away first; otherwise it lingers
    /// over that keypad until this field has left the screen.
    private func next() {
        guard viewModel.nameIsValid, !leaving else { return }
        leaving = true
        focused = false
        Task {
            try? await Task.sleep(for: Self.keyboardHide)
            viewModel.continueFromName()
            leaving = false
        }
    }
}
