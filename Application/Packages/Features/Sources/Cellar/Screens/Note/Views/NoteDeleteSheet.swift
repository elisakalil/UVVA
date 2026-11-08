import DesignSystem
import SwiftUI

/// "Delete this note?" on the paper: Delete, or Cancel to keep it (CELLAR-R28).
struct NoteDeleteSheet: View {
    var resources: NoteResourcesUIModel
    var isWorking: Bool
    var onDelete: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(resources.deleteTitleText)
                .font(UVVAFont.sans(26, .ultraLight))
                .tracking(-0.5)
            Text(resources.deleteBodyText)
                .font(UVVAFont.sans(13))
                .lineSpacing(4)
                .opacity(0.74)
                .padding(.top, 10)
            Button(action: onDelete) {
                Text(resources.deleteText.uppercased())
                    .font(UVVAFont.sans(9.5, .semibold))
                    .tracking(2.85)
                    .foregroundStyle(UVVAColor.creamFill)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(NotePalette.ink, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isWorking)
            .padding(.top, 32)
            Button(action: onCancel) {
                Text(resources.cancelText.uppercased())
                    .font(UVVAFont.sans(9.5, .semibold))
                    .tracking(2.85)
                    .opacity(0.8)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .overlay { Capsule().strokeBorder(NotePalette.ink.opacity(0.35), lineWidth: 0.5) }
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
        .foregroundStyle(NotePalette.ink)
        .padding(.horizontal, 26)
        .padding(.top, 28)
        .presentationDetents([.height(330)])
        .presentationDragIndicator(.visible)
        .presentationBackground(NotePalette.paper)
        .presentationCornerRadius(28)
    }
}
