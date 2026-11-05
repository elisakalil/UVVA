import DesignSystem
import SwiftUI

/// 01 / 02 · Name (ONB-R14 to R16).
struct NameView<ViewModel: NameViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @FocusState private var focused: Bool
    @State private var leaving = false

    /// About how long the system keyboard takes to slide away.
    static var keyboardHide: Duration { .milliseconds(250) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SignUpHeader(counter: viewModel.uiModel.counter, onBack: { viewModel.back() })
            SignUpTitle(title: viewModel.uiModel.andWhatShouldWeCallYouText,
                        detail: viewModel.uiModel.yourFirstNameIsEnoughText,
                        detailWidth: 265)
                .padding(.top, 56)

            TextField("", text: Binding(get: { viewModel.uiModel.name }, set: { viewModel.updateName($0) }), prompt: Text(verbatim: viewModel.uiModel.placeholder).foregroundStyle(UVVAColor.creamFill.opacity(0.28)))
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

            Text(viewModel.uiModel.validationMessage.uppercased())
                .font(UVVAFont.sans(9))
                .tracking(2.3)
                .opacity(0.35)
                .padding(.top, 16)
                .contentTransition(.opacity)

            Spacer(minLength: 20)
            ActionButton(viewModel.uiModel.continueText, isEnabled: viewModel.uiModel.isValid && !leaving,
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
        guard viewModel.uiModel.isValid, !leaving else { return }
        leaving = true
        focused = false
        Task {
            try? await Task.sleep(for: Self.keyboardHide)
            viewModel.continueFromName()
            leaving = false
        }
    }
}

#Preview {
    NameView(viewModel: NamePreviewViewModel())
}

@MainActor
private final class NamePreviewViewModel: NameViewModelProtocol {
    @Published var uiModel = NameUIModel(name: "Elisa")
    func updateName(_ name: String) { uiModel.name = name }
    func back() {}
    func continueFromName() {}
}
