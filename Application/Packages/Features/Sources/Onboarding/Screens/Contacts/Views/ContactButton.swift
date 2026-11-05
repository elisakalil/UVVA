import DesignSystem
import SwiftUI

/// Outline while waiting for the tap, solid cream once done.
struct ContactButton: View {
    var state: ContactRowState
    var action: () -> Void

    private var uiModel: ContactButtonUIModel { ContactButtonUIModel(state: state) }

    var body: some View {
        Button(action: action) {
            Text(uiModel.title.uppercased())
                .font(UVVAFont.sans(9, .semibold))
                .tracking(2.2)
                .foregroundStyle(uiModel.isDone ? UVVAColor.mossDeep : UVVAColor.creamFill)
                .padding(.horizontal, 12)
                .frame(minWidth: 70, minHeight: 44)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(UVVAColor.creamFill.opacity(uiModel.isDone ? 1 : 0))
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(UVVAColor.creamFill.opacity(uiModel.isDone ? 0 : 0.45), lineWidth: 0.5))
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.3), value: state)
    }
}
