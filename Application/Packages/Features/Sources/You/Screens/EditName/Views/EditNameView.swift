import DesignSystem
import SwiftUI

/// Change the name (YOU-R14, R15).
struct EditNameView: View {
    @Bindable var viewModel: EditNameViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool


    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Your first name", bundle: .module).font(UVVAFont.sans(26, .ultraLight)).padding(.top, 30)
            TextField("", text: $viewModel.name)
                .font(UVVAFont.sans(26))
                .textContentType(.givenName)
                .focused($focused)
                .padding(.bottom, 13)
                .overlay(alignment: .bottom) { Rectangle().opacity(0.3).frame(height: 0.5) }
                .padding(.top, 30)
            Text((viewModel.isValid ? String(localized: "Nice to meet you", bundle: .module)
                          : String(localized: "At least two letters", bundle: .module)).uppercased())
                .font(UVVAFont.sans(9)).tracking(2.3).opacity(0.35).padding(.top, 16)
            if let notice = viewModel.notice {
                Text(notice).font(UVVAFont.sans(12)).padding(.top, 12)
            }
            Spacer()
            ActionButton(String(localized: "Save", bundle: .module), isEnabled: viewModel.isValid && !viewModel.isSaving) {
                Task { if await viewModel.saveName(viewModel.name) { dismiss() } }
            }
        }
        .padding(30)
        .foregroundStyle(UVVAColor.creamFill)
        .presentationBackground(UVVAColor.mossDeep)
        .presentationDetents([.medium])
        .onAppear { viewModel.prepare(); focused = true }
    }
}
