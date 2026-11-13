import SwiftUI

/// Full-width pill button. Filled is the cream main action; outline is the quiet one beside it.
public struct PillButton<Label: View>: View {
    public enum Style: Sendable { case filled, outline }

    var style: Style
    var tint: Color?
    var action: () -> Void
    var label: Label

    public init(style: Style = .filled, tint: Color? = nil, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.style = style
        self.tint = tint
        self.action = action
        self.label = label()
    }

    public var body: some View {
        Button(action: action) {
            label
                .font(UVVAFont.sans(14, .regular))
                .foregroundStyle(style == .filled ? UVVAColor.ink : (tint ?? UVVAColor.cream))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background {
                    if style == .filled {
                        Capsule().fill(tint ?? UVVAColor.creamFill)
                    } else {
                        Capsule().strokeBorder((tint ?? UVVAColor.cream).opacity(0.4), lineWidth: 0.75)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
