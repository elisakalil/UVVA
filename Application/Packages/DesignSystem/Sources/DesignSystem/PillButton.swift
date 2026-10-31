import SwiftUI

/// Full-width pill button. Filled is the cream main action; outline is the quiet one beside it.
public struct PillButton<Label: View>: View {
    public enum Style: Sendable { case filled, outline }

    var style: Style
    var action: () -> Void
    var label: Label

    public init(style: Style = .filled, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.style = style
        self.action = action
        self.label = label()
    }

    public var body: some View {
        Button(action: action) {
            label
                .font(UVVAFont.sans(14, .regular))
                .foregroundStyle(style == .filled ? UVVAColor.ink : UVVAColor.cream)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background {
                    if style == .filled {
                        Capsule().fill(UVVAColor.creamFill)
                    } else {
                        Capsule().strokeBorder(UVVAColor.cream.opacity(0.4), lineWidth: 0.75)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
