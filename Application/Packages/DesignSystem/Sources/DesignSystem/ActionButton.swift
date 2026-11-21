import SwiftUI

/// The tall pill that moves a flow on ("Read my palate", "Next", "Keep this map").
/// Filled is cream with ink text; outline is a thin cream ring. Caps, 9.5 pt, wide tracking.
public struct ActionButton: View {
    public enum Style: Sendable { case filled, outline }

    var title: String
    var style: Style
    var isEnabled: Bool
    var action: () -> Void

    @Environment(\.isEnabled) private var environmentEnabled

    public init(_ title: String, style: Style = .filled, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.isEnabled = isEnabled
        self.action = action
    }

    private var enabled: Bool { isEnabled && environmentEnabled }

    public var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(UVVAFont.sans(9.5, .semibold))
                .tracking(3.2)
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background {
                    switch (style, enabled) {
                    case (.filled, true):
                        Capsule().fill(UVVAColor.creamFill)
                    case (.filled, false):
                        Capsule().strokeBorder(UVVAColor.creamFill.opacity(DisabledPill.ringOpacity), lineWidth: 1)
                    case (.outline, _):
                        Capsule().strokeBorder(UVVAColor.creamFill.opacity(0.28), lineWidth: 1)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(style == .outline && !enabled ? 0.4 : 1)
        .animation(.easeOut(duration: 0.2), value: enabled)
    }

    private var foreground: Color {
        switch (style, enabled) {
        case (.filled, true): UVVAColor.mossDeep
        case (.filled, false): UVVAColor.creamFill.opacity(DisabledPill.textOpacity)
        case (.outline, _): UVVAColor.creamFill
        }
    }
}
