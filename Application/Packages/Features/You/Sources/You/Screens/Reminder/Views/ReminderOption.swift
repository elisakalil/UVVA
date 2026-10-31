import DesignSystem
import SwiftUI

/// A moment of the reminder, or "Turn reminders off".
struct ReminderOption: View {
    var title: String
    var detail: String?
    var subtitle: String?
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(UVVAFont.sans(14.5))
                    if let subtitle { Text(subtitle).font(UVVAFont.sans(11.5)).opacity(0.8) }
                }
                Spacer()
                if let detail { Text(detail).font(UVVAFont.sans(12)).tracking(1.7).opacity(0.86) }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 8).fill(UVVAColor.creamFill.opacity(isSelected ? 0.16 : 0.03)))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .strokeBorder(UVVAColor.creamFill.opacity(isSelected ? 0.7 : 0.25), lineWidth: 0.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
