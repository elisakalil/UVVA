import SwiftUI

/// Full-width pill button. Filled is the cream main action; outline is the quiet one beside it.
public struct PillButton<Label: View>: View {
    public enum Style: Sendable { case filled, outline }

    var style: Style
    var tint: Color?
    var action: () -> Void
    var label: Label

    @Environment(\.isEnabled) private var isEnabled

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
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background {
                    switch (style, isEnabled) {
                    case (.filled, true):
                        Capsule().fill(fill)
                    case (.filled, false):
                        Capsule().strokeBorder(fill.opacity(DisabledPill.ringOpacity), lineWidth: 0.75)
                    case (.outline, _):
                        Capsule().strokeBorder((tint ?? UVVAColor.cream).opacity(0.4), lineWidth: 0.75)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.2), value: isEnabled)
    }

    private var fill: Color { tint ?? UVVAColor.creamFill }

    private var foreground: Color {
        switch (style, isEnabled) {
        case (.filled, true): UVVAColor.ink
        case (.filled, false): fill.opacity(DisabledPill.textOpacity)
        case (.outline, _): tint ?? UVVAColor.cream
        }
    }
}
