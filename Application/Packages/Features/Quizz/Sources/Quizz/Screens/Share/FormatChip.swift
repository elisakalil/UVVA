import DesignSystem
import SwiftUI

/// Story / WhatsApp switch above the share button.
struct FormatChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(UVVAFont.sans(8.5))
                .tracking(1.9)
                .opacity(isSelected ? 1 : 0.55)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background {
                    Capsule()
                        .fill(UVVAColor.creamFill.opacity(isSelected ? 0.14 : 0))
                        .overlay(Capsule().strokeBorder(UVVAColor.creamFill.opacity(isSelected ? 0.5 : 0.2), lineWidth: 0.5))
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
