import Core
import DesignSystem
import SwiftUI

/// Change or remove the phone (YOU-R15). An empty field removes the number and its contact key.
struct EditPhoneView: View {
    @State var country: PhoneCountry
    @State var national: String
    var onSave: (String, PhoneCountry) async -> Bool
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    private var digits: String { national.filter(\.isNumber) }
    private var isValid: Bool { digits.isEmpty || PhoneNumber.e164(national: digits, country: country) != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Your phone number", bundle: .module).font(UVVAFont.sans(26, .ultraLight)).padding(.top, 30)
            Text("So friends who have you in their contacts can find you here. Leave it empty to remove it.", bundle: .module)
                .font(UVVAFont.sans(13)).lineSpacing(5).opacity(0.55).padding(.top, 14)
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Menu {
                    ForEach(PhoneCountries.all.sorted { $0.name().localizedStandardCompare($1.name()) == .orderedAscending }) { item in
                        Button("\(item.name())  +\(item.callingCode)") { country = item }
                    }
                } label: {
                    Text("+" + country.callingCode).font(UVVAFont.sans(22)).tracking(0.9)
                        .padding(.horizontal, 13).padding(.vertical, 9)
                        .overlay(Capsule().strokeBorder(UVVAColor.creamFill.opacity(0.2), lineWidth: 0.5))
                }
                TextField("", text: $national)
                    .keyboardType(.numberPad)
                    .textContentType(.telephoneNumber)
                    .font(UVVAFont.sans(22))
                    .focused($focused)
            }
            .padding(.bottom, 13)
            .overlay(alignment: .bottom) { Rectangle().opacity(0.3).frame(height: 0.5) }
            .padding(.top, 30)
            Spacer()
            ActionButton(String(localized: "Save", bundle: .module), isEnabled: isValid) {
                Task { if await onSave(digits, country) { dismiss() } }
            }
        }
        .padding(30)
        .foregroundStyle(UVVAColor.creamFill)
        .presentationBackground(UVVAColor.mossDeep)
        .presentationDetents([.medium, .large])
        .onAppear { focused = true }
    }
}
