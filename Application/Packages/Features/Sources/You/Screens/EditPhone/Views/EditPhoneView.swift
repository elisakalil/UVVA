import Core
import DesignSystem
import SwiftUI

/// Change or remove the phone (YOU-R15), in the sheet of the account rows. An empty field removes the number and its
/// contact key.
struct EditPhoneView<ViewModel: EditPhoneViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    var body: some View {
        YouSheet(title: viewModel.uiModel.yourPhoneNumberText, message: viewModel.uiModel.soFriendsWhoHaveYouText,
                 height: 370) {
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Menu {
                    ForEach(PhoneCountries.all.sorted { $0.name().localizedStandardCompare($1.name()) == .orderedAscending }) { item in
                        Button("\(item.name())  +\(item.callingCode)") { viewModel.selectCountry(item) }
                    }
                } label: {
                    Text("+" + viewModel.uiModel.country.callingCode).font(UVVAFont.sans(22)).tracking(0.9)
                        .padding(.horizontal, 13).padding(.vertical, 9)
                        .overlay(Capsule().strokeBorder(UVVAColor.creamFill.opacity(0.2), lineWidth: 0.5))
                }
                TextField("", text: Binding(get: { viewModel.uiModel.national }, set: { viewModel.updateNational($0) }))
                    .keyboardType(.numberPad)
                    .textContentType(.telephoneNumber)
                    .font(UVVAFont.sans(22))
                    .focused($focused)
            }
            .padding(.bottom, 13)
            .overlay(alignment: .bottom) { Rectangle().opacity(0.3).frame(height: 0.5) }
            .padding(.top, 26)
            if let notice = viewModel.uiModel.notice {
                Text(notice).font(UVVAFont.sans(12)).padding(.top, 12)
            }
            Spacer(minLength: 20)
            ActionButton(viewModel.uiModel.saveText, isEnabled: viewModel.uiModel.isValid && !viewModel.uiModel.isSaving) {
                Task { if await viewModel.savePhone(national: viewModel.uiModel.digits, country: viewModel.uiModel.country) { dismiss() } }
            }
        }
        .onAppear { viewModel.prepare(); focused = true }
    }
}
