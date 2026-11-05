import DesignSystem
import SwiftUI

/// "By continuing you agree to the Terms and the Privacy Policy." Both links open the Legal screen (ONB-R28, R31).
struct LegalAgreement: View {
    var uiModel = LegalAgreementUIModel()
    var onOpen: (LegalTab) -> Void

    private var text: AttributedString {
        var text = uiModel.text
        for run in text.runs where run.link != nil {
            text[run.range].foregroundColor = UVVAColor.creamFill
        }
        return text
    }

    var body: some View {
        Text(text)
            .font(UVVAFont.sans(11))
            .lineSpacing(5)
            .multilineTextAlignment(.center)
            .foregroundStyle(UVVAColor.creamFill.opacity(0.55))
            .frame(maxWidth: 300)
            .environment(\.openURL, OpenURLAction { url in
                onOpen(url.host() == "privacy" ? .privacy : .terms)
                return .handled
            })
    }
}
