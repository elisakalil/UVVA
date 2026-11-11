import DesignSystem
import SwiftUI

/// Change the name (YOU-R14, R15), in the sheet of the account rows.
struct EditNameView<ViewModel: EditNameViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool


    var body: some View {
        YouSheet(title: viewModel.uiModel.yourFirstNameText, height: 340) {
            TextField("", text: Binding(get: { viewModel.uiModel.name }, set: { viewModel.updateName($0) }))
                .font(UVVAFont.sans(26))
                .textContentType(.givenName)
                .focused($focused)
                .padding(.bottom, 13)
                .overlay(alignment: .bottom) { Rectangle().opacity(0.3).frame(height: 0.5) }
                .padding(.top, 26)
            Text(viewModel.uiModel.validationMessage.uppercased())
                .font(UVVAFont.sans(9)).tracking(2.3).opacity(0.35).padding(.top, 16)
            if let notice = viewModel.uiModel.notice {
                Text(notice).font(UVVAFont.sans(12)).padding(.top, 12)
            }
            Spacer(minLength: 20)
            ActionButton(viewModel.uiModel.saveText, isEnabled: viewModel.uiModel.isValid && !viewModel.uiModel.isSaving) {
                Task { if await viewModel.saveName(viewModel.uiModel.name) { dismiss() } }
            }
        }
        .onAppear { viewModel.prepare(); focused = true }
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        EditNameView(viewModel: EditNamePreviewViewModel())
    }
}

@MainActor
private final class EditNamePreviewViewModel: EditNameViewModelProtocol {
    @Published var uiModel = EditNameUIModel(name: "Elisa")
    func prepare() {}
    func updateName(_ name: String) { uiModel.name = name }
    func saveName(_ name: String) async -> Bool { true }
}
