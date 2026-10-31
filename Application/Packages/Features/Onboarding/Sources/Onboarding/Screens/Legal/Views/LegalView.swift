import DesignSystem
import SwiftUI

/// Terms and Privacy (ONB-R08). The text is a mock until the real one is written (ONB-R08a).
struct LegalView: View {
    @State var tab: LegalTab
    var onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                BackChevron(action: onBack)
                Spacer()
                Text(String(localized: "Legal", bundle: .module).uppercased())
                    .font(UVVAFont.sans(9)).tracking(2.7).opacity(0.45)
            }
            .padding(.horizontal, 30)

            VStack(alignment: .leading, spacing: 0) {
                Text(tab == .terms ? String(localized: "Terms of Use", bundle: .module)
                                   : String(localized: "Privacy Policy", bundle: .module))
                    .font(UVVAFont.sans(30, .ultraLight))
                    .tracking(-0.4)
                Text("Last updated 12 August 2026", bundle: .module)
                    .font(UVVAFont.sans(11)).tracking(0.7).opacity(0.4)
                    .padding(.top, 10)
                LegalTabs(tab: $tab).padding(.top, 22)
            }
            .padding(.horizontal, 30)
            .padding(.top, 34)

            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    ForEach(LegalText.sections(tab), id: \.title) { section in
                        VStack(alignment: .leading, spacing: 9) {
                            Text(section.title.uppercased()).font(UVVAFont.sans(9)).tracking(2.5).opacity(0.42)
                            Text(section.body).font(UVVAFont.sans(13.5)).lineSpacing(8).opacity(0.72)
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 24)
            }
            .scrollIndicators(.hidden)
            .scrollEdgeFade(18)

            ActionButton(String(localized: "I understand", bundle: .module), action: onBack)
                .padding(.horizontal, 30)
                .padding(.top, 14)
                .padding(.bottom, 12)
        }
        .padding(.top, 16)
    }
}
