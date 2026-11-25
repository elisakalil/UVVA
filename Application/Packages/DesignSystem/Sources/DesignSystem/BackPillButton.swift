import SwiftUI

/// A small word in caps inside a thin outlined pill: a friend's "Back" and the table's "Expand".
public struct PillLabel: View {
    var text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(7.5, .semibold))
            .tracking(1.65)
            .opacity(0.75)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .overlay(Capsule().strokeBorder(UVVAColor.creamFill.opacity(0.32), lineWidth: 0.5))
    }
}

/// "Back" in an outlined pill, as at the top of a friend: the back of the Onboarding, the Quiz and Friends.
public struct BackPillButton: View {
    var title: String
    var action: () -> Void

    /// `title` defaults to "Back" in the app's language.
    public init(title: String? = nil, action: @escaping () -> Void) {
        self.title = title ?? String(localized: "Back", bundle: .module)
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            PillLabel(text: title)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
}
