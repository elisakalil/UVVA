import SwiftUI

/// Selectable chip of the "Choose your wine" filters.
/// Selected: cream with ink text. Idle: a faint glass outline with cream text.
public struct Chip: View {
    var text: String
    var isSelected: Bool
    var action: () -> Void

    public init(text: String, isSelected: Bool, action: @escaping () -> Void) {
        self.text = text
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(text)
                .font(UVVAFont.sans(13, isSelected ? .medium : .regular))
                .tracking(0.6)
                .lineLimit(1)
                .foregroundStyle(isSelected ? UVVAColor.ink : UVVAColor.cream84)
                .padding(.horizontal, 13)
                .frame(minHeight: 30)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(LinearGradient(colors: [UVVAColor.creamFill, UVVAColor.creamFill.opacity(0.88)],
                                                 startPoint: .top, endPoint: .bottom))
                            .shadow(color: .black.opacity(0.14), radius: 6, y: 3)
                    } else {
                        Capsule()
                            .fill(.white.opacity(0.04))
                            .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 0.75))
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
