import DesignSystem
import SwiftUI

/// The `‹` of the sign-up screens.
struct BackChevron: View {
    var uiModel = OnboardingChromeUIModel()
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(uiModel.backSymbol)
                .font(UVVAFont.sans(34, .ultraLight))
                .opacity(0.5)
                .frame(width: 44, height: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(uiModel.backTitle))
    }
}
