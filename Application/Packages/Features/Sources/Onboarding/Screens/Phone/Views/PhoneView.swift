import Core
import DesignSystem
import SwiftUI

/// 02 / 02 · Phone (ONB-R03 to R07, R35), with its own keypad and the country picker (D8).
struct PhoneView<ViewModel: PhoneViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @State private var choosingCountry = false
    /// Bumped by a tap on the number, so the keypad shows it is where to type.
    @State private var keypadHint = 0

    var body: some View {
        let model = viewModel.uiModel
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                SignUpHeader(counter: model.counter, onBack: { viewModel.back() })
                SignUpTitle(title: viewModel.uiModel.whatIsYourPhoneNumberText,
                            detail: viewModel.uiModel.soFriendsWhoHaveYouInText,
                            detailWidth: 280)
                    .padding(.top, 40)

                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Button { choosingCountry = true } label: {
                        HStack(spacing: 8) {
                            Text(model.dialCode).font(UVVAFont.sans(22)).tracking(0.9)
                            Text(model.countryChevron).font(UVVAFont.sans(14, .ultraLight)).rotationEffect(.degrees(90)).opacity(0.6)
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 9)
                        .background(GlassPill())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(model.countryAccessibility))
                    // The keypad below is always the input: the field shows it is live with a caret and a
                    // bright line, and a tap on it lights the keypad up instead of doing nothing.
                    // The caret sits before the example while it is empty and after the last digit once typing.
                    Text(model.number)
                        .font(UVVAFont.sans(22))
                        .tracking(0.9)
                        .opacity(model.isEmpty ? 0.35 : 1)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.2), value: model.number)
                        .overlay(alignment: model.isEmpty ? .leading : .trailing) {
                            PhoneCaret().offset(x: model.isEmpty ? -5 : 5)
                        }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture { keypadHint += 1 }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(model.numberAccessibility))
                    .accessibilityValue(Text(model.isEmpty ? "" : model.number))
                }
                .padding(.bottom, 13)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(UVVAColor.creamFill).opacity(0.85).frame(height: 1)
                }
                .padding(.top, 40)

                if let notice = viewModel.uiModel.notice {
                    Text(notice).font(UVVAFont.sans(12)).multilineTextAlignment(.center)
                        .padding(.top, 12)
                }

                Spacer(minLength: 12)

                ActionButton(viewModel.uiModel.continueText,
                             isEnabled: model.canContinue && !model.isSaving) {
                    Task { await viewModel.continueWithPhone() }
                }
                .frame(height: 96)
            }
            .padding(.horizontal, 30)
            .padding(.top, 16)
            .padding(.bottom, 18)

            PhoneKeypad(hint: keypadHint, onDigit: viewModel.press, onDelete: viewModel.deleteDigit)
        }
        .sheet(isPresented: $choosingCountry) {
            CountryPicker(selected: model.country) { country in
                viewModel.select(country)
                choosingCountry = false
            }
            .presentationDetents([.medium, .large])
            .presentationBackground(UVVAColor.mossDeep)
        }
    }
}

/// The blinking text cursor of the number field.
private struct PhoneCaret: View {
    @State private var visible = true

    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(UVVAColor.creamFill)
            .frame(width: 2, height: 24)
            .opacity(visible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { visible = false }
            }
            .accessibilityHidden(true)
    }
}
