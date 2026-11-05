import Core
import DesignSystem
import SwiftUI

/// 02 / 02 · Phone (ONB-R03 to R07, R35), with its own keypad and the country picker (D8).
struct PhoneView: View {
    var viewModel: PhoneViewModel
    @State private var choosingCountry = false

    var body: some View {
        let model = viewModel.phoneModel
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                SignUpHeader(counter: "02 / 02", onBack: { viewModel.back() })
                SignUpTitle(title: String(localized: "What is your phone number?", bundle: .module),
                            detail: String(localized: "So friends who have you in their contacts can find you here. We never send you a code or a message.", bundle: .module),
                            detailWidth: 280)
                    .padding(.top, 40)

                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Button { choosingCountry = true } label: {
                        HStack(spacing: 8) {
                            Text(model.dialCode).font(UVVAFont.sans(22)).tracking(0.9)
                            Text("›").font(UVVAFont.sans(14, .ultraLight)).rotationEffect(.degrees(90)).opacity(0.6)
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 9)
                        .background(GlassPill())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Country, \(model.country.name())", bundle: .module))
                    Text(model.number)
                        .font(UVVAFont.sans(22))
                        .tracking(0.9)
                        .opacity(model.isEmpty ? 0.35 : 1)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.bottom, 13)
                .overlay(alignment: .bottom) { Rectangle().opacity(0.3).frame(height: 0.5) }
                .padding(.top, 40)

                if let notice = viewModel.notice {
                    Text(notice).font(UVVAFont.sans(12)).multilineTextAlignment(.center)
                        .padding(.top, 12)
                }

                Spacer(minLength: 12)

                ZStack {
                    VStack(spacing: 14) {
                        Text("Optional. You can still add friends with your invite link.", bundle: .module)
                            .font(UVVAFont.sans(12)).lineSpacing(5).opacity(0.6)
                            .multilineTextAlignment(.center).frame(maxWidth: 260)
                        Button { Task { await viewModel.skipPhone() } } label: {
                            Text(String(localized: "Skip for now", bundle: .module).uppercased())
                                .font(UVVAFont.sans(9.5, .semibold)).tracking(2.85)
                                .frame(minHeight: 44).padding(.horizontal, 20).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .opacity(model.isEmpty ? 1 : 0)
                    .offset(y: model.isEmpty ? 0 : 10)
                    .allowsHitTesting(model.isEmpty)

                    ActionButton(String(localized: "Continue", bundle: .module),
                                 isEnabled: model.canContinue && !model.isSaving) {
                        Task { await viewModel.continueWithPhone() }
                    }
                    .opacity(model.isEmpty ? 0 : 1)
                    .offset(y: model.isEmpty ? 10 : 0)
                    .allowsHitTesting(!model.isEmpty)
                }
                .frame(height: 96)
                .animation(.easeOut(duration: 0.5), value: model.isEmpty)
            }
            .padding(.horizontal, 30)
            .padding(.top, 16)
            .padding(.bottom, 18)

            PhoneKeypad(onDigit: viewModel.press, onDelete: viewModel.deleteDigit)
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
