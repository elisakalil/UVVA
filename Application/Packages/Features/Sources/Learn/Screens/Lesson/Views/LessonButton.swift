import DesignSystem
import SwiftUI

/// The pill at the foot of the player: the label on the left and an arrow on the right.
/// Filled cream on wine, wine on the tip; a faint ring while it cannot be used yet.
struct LessonButton: View {
    enum Style { case filled, onTip }

    var title: String
    var style: Style = .filled
    var isEnabled = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title.uppercased())
                Spacer()
                Text(verbatim: "→")
            }
            .font(UVVAFont.sans(11, .regular))
            .tracking(2.4)
            .foregroundStyle(foreground)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background {
                switch (style, isEnabled) {
                case (.filled, true): Capsule().fill(LessonPalette.ink)
                case (.onTip, true): Capsule().fill(LessonPalette.wine)
                case (_, false): Capsule().strokeBorder(LessonPalette.ink.opacity(0.22), lineWidth: 1)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private var foreground: Color {
        guard isEnabled else { return LessonPalette.ink.opacity(0.45) }
        return switch style {
        case .filled: LessonPalette.wine
        case .onTip: LessonPalette.ink
        }
    }
}
