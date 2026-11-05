import DesignSystem
import SwiftUI

/// The glass sheet that asks before signing out or deleting (YOU-R26, R27).
struct ConfirmSheet: View {
    var kind: ConfirmKind
    var isWorking: Bool
    var onConfirm: () async -> Void
    var onCancel: () -> Void

    private var uiModel: ConfirmUIModel { ConfirmUIModel(kind: kind) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(uiModel.eyebrow.uppercased()).font(UVVAFont.sans(9, .semibold)).tracking(3.2).opacity(0.82)
                .padding(.top, 26)
            Text(uiModel.title).font(UVVAFont.sans(28, .ultraLight)).tracking(-0.4).padding(.top, 12)
            Text(uiModel.message).font(UVVAFont.sans(13)).lineSpacing(5).opacity(0.86).padding(.top, 10)
            ActionButton(uiModel.confirm, isEnabled: !isWorking) { Task { await onConfirm() } }
                .padding(.top, 30)
            TextAction(uiModel.cancel, opacity: 0.72, action: onCancel)
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
        }
        .padding(.horizontal, 26)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .fill(LinearGradient(colors: [Color(hex: 0x4E5A40).opacity(0.94), Color(hex: 0x38422E).opacity(0.96)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .background(.ultraThinMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
                .ignoresSafeArea()
        }
        .foregroundStyle(UVVAColor.creamFill)
    }
}
