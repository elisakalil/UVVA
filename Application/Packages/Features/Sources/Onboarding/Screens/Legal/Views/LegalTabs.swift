import DesignSystem
import SwiftUI

/// Terms / Privacy switch, on a glass pill.
struct LegalTabs: View {
    var uiModel = LegalTabsUIModel()
    @Binding var tab: LegalTab

    var body: some View {
        HStack(spacing: 4) {
            item(uiModel.termsText, .terms)
            item(uiModel.privacyText, .privacy)
        }
        .padding(4)
        .background(GlassPill())
    }

    private func item(_ title: String, _ value: LegalTab) -> some View {
        let isOn = tab == value
        return Button { withAnimation(.easeOut(duration: 0.2)) { tab = value } } label: {
            Text(title.uppercased())
                .font(UVVAFont.sans(9.5, .regular))
                .tracking(2.5)
                .foregroundStyle(isOn ? UVVAColor.mossDeep : UVVAColor.creamFill.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Capsule().fill(UVVAColor.creamFill.opacity(isOn ? 0.9 : 0)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
