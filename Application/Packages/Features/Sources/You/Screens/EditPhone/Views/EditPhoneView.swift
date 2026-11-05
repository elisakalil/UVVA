import Core
import DesignSystem
import SwiftUI

/// Change or remove the phone (YOU-R15). An empty field removes the number and its contact key.
struct EditPhoneView<ViewModel: EditPhoneViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(viewModel.uiModel.yourPhoneNumberText).font(UVVAFont.sans(26, .ultraLight)).padding(.top, 30)
            Text(viewModel.uiModel.soFriendsWhoHaveYouText)
                .font(UVVAFont.sans(13)).lineSpacing(5).opacity(0.55).padding(.top, 14)
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
            .padding(.top, 30)
            if let notice = viewModel.uiModel.notice {
                Text(notice).font(UVVAFont.sans(12)).padding(.top, 12)
            }
            Spacer()
            ActionButton(viewModel.uiModel.saveText, isEnabled: viewModel.uiModel.isValid && !viewModel.uiModel.isSaving) {
                Task { if await viewModel.savePhone(national: viewModel.uiModel.digits, country: viewModel.uiModel.country) { dismiss() } }
            }
        }
        .padding(30)
        .foregroundStyle(UVVAColor.creamFill)
        .presentationBackground(UVVAColor.mossDeep)
        .presentationDetents([.medium, .large])
        .onAppear { viewModel.prepare(); focused = true }
    }
}
