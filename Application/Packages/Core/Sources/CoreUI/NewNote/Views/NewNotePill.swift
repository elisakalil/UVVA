#if os(iOS)
import DesignSystem
import SwiftUI

/// The capsule buttons of the new note: filled for the way forward, outlined for the other way.
struct NewNotePill: View {
    enum Style { case filled, outlined }

    var title: String
    var style: Style
    /// The ink of the page: cream over the camera and messages, dark ink on paper.
    var ink: Color
    /// What a filled pill's title is written in.
    var ground: Color
    var isEnabled = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(UVVAFont.sans(9.5, .semibold))
                .tracking(2.85)
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background {
                    switch (style, isEnabled) {
                    case (.filled, true): Capsule().fill(ink)
                    case (.filled, false): Capsule().strokeBorder(ink.opacity(DisabledPill.ringOpacity), lineWidth: 0.75)
                    case (.outlined, _): Capsule().strokeBorder(ink.opacity(0.35), lineWidth: 0.5)
                    }
                }
                .contentShape(Capsule())
                .opacity(style == .outlined && !isEnabled ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(.easeOut(duration: 0.2), value: isEnabled)
    }

    private var foreground: Color {
        switch (style, isEnabled) {
        case (.filled, true): ground
        case (.filled, false): ink.opacity(DisabledPill.textOpacity)
        case (.outlined, _): ink.opacity(0.8)
        }
    }
}
#endif
