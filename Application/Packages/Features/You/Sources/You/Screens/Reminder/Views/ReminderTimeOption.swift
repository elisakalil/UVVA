import DesignSystem
import SwiftUI

/// "Another time": any hour and minute (D8, decided 2026-10-31).
struct ReminderTimeOption: View {
    @Binding var time: Date
    var isSelected: Bool
    var onPick: (Date) -> Void

    var body: some View {
        HStack {
            Text("Another time", bundle: .module).font(UVVAFont.sans(14.5))
            Spacer()
            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .colorScheme(.dark)
                .tint(UVVAColor.creamFill)
                .onChange(of: time) { _, value in onPick(value) }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(UVVAColor.creamFill.opacity(isSelected ? 0.16 : 0.03)))
        .overlay(RoundedRectangle(cornerRadius: 8)
            .strokeBorder(UVVAColor.creamFill.opacity(isSelected ? 0.7 : 0.25), lineWidth: 0.5))
        .contentShape(Rectangle())
        .onTapGesture { onPick(time) }
    }
}
