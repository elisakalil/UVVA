import DesignSystem
import SwiftUI

/// Change the name (YOU-R14, R15).
struct EditNameView<ViewModel: EditNameViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool


    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(viewModel.uiModel.yourFirstNameText).font(UVVAFont.sans(26, .ultraLight)).padding(.top, 30)
            TextField("", text: Binding(get: { viewModel.uiModel.name }, set: { viewModel.updateName($0) }))
                .font(UVVAFont.sans(26))
                .textContentType(.givenName)
                .focused($focused)
                .padding(.bottom, 13)
                .overlay(alignment: .bottom) { Rectangle().opacity(0.3).frame(height: 0.5) }
                .padding(.top, 30)
            Text(viewModel.uiModel.validationMessage.uppercased())
                .font(UVVAFont.sans(9)).tracking(2.3).opacity(0.35).padding(.top, 16)
            if let notice = viewModel.uiModel.notice {
                Text(notice).font(UVVAFont.sans(12)).padding(.top, 12)
            }
            Spacer()
            ActionButton(viewModel.uiModel.saveText, isEnabled: viewModel.uiModel.isValid && !viewModel.uiModel.isSaving) {
                Task { if await viewModel.saveName(viewModel.uiModel.name) { dismiss() } }
            }
        }
        .padding(30)
        .foregroundStyle(UVVAColor.creamFill)
        .presentationBackground(UVVAColor.mossDeep)
        .presentationDetents([.medium])
        .onAppear { viewModel.prepare(); focused = true }
    }
}

#Preview {
    EditNameView(viewModel: EditNamePreviewViewModel())
}

@MainActor
private final class EditNamePreviewViewModel: EditNameViewModelProtocol {
    @Published var uiModel = EditNameUIModel(name: "Elisa")
    func prepare() {}
    func updateName(_ name: String) { uiModel.name = name }
    func saveName(_ name: String) async -> Bool { true }
}
