import SwiftUI

/// The tall pill that moves a flow on ("Read my palate", "Next", "Keep this map").
/// Filled is cream with ink text; outline is a thin cream ring. Caps, 9.5 pt, wide tracking.
public struct ActionButton: View {
    public enum Style: Sendable { case filled, outline }

    var title: String
    var style: Style
    var isEnabled: Bool
    var action: () -> Void

    public init(_ title: String, style: Style = .filled, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(UVVAFont.sans(9.5, .semibold))
                .tracking(3.2)
                .foregroundStyle(style == .filled ? UVVAColor.mossDeep : UVVAColor.creamFill)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background {
                    if style == .filled {
                        Capsule().fill(UVVAColor.creamFill)
                    } else {
                        Capsule().strokeBorder(UVVAColor.creamFill.opacity(0.28), lineWidth: 1)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .animation(.easeOut(duration: 0.2), value: isEnabled)
    }
}
