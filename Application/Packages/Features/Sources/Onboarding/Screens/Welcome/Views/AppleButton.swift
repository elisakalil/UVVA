import DesignSystem
import SwiftUI

/// "Continue with Apple": the cream pill with the Apple logo (ONB-R29).
struct AppleButton: View {
    var uiModel = AppleButtonUIModel()
    var isEnabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: uiModel.appleLogoIcon).font(.system(size: 15))
                Text(uiModel.continueWithAppleText.uppercased())
                    .font(UVVAFont.sans(9.5, .semibold))
                    .tracking(2.85)
            }
            .foregroundStyle(UVVAColor.mossDeep)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Capsule().fill(UVVAColor.creamFill))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }
}
