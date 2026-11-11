#if os(iOS)
import DesignSystem
import SwiftUI

/// A question on paper that slides up from the foot: a title, a line, the action and the way out
/// ("Delete this note?", CELLAR-R28; "Discard this note?", CELLAR-R25).
public struct CellarPaperSheet: View {
    var title: String
    var message: String
    var primary: String
    var secondary: String
    var isWorking = false
    var onPrimary: () -> Void
    var onSecondary: () -> Void

    public init(title: String, message: String, primary: String, secondary: String, isWorking: Bool = false,
                onPrimary: @escaping () -> Void, onSecondary: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.primary = primary
        self.secondary = secondary
        self.isWorking = isWorking
        self.onPrimary = onPrimary
        self.onSecondary = onSecondary
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(UVVAFont.sans(26, .ultraLight))
                .tracking(-0.5)
            Text(message)
                .font(UVVAFont.sans(13))
                .lineSpacing(4)
                .opacity(0.74)
                .padding(.top, 10)
            Button(action: onPrimary) {
                Text(primary.uppercased())
                    .font(UVVAFont.sans(9.5, .semibold))
                    .tracking(2.85)
                    .foregroundStyle(UVVAColor.creamFill)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(NotePalette.ink, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isWorking)
            .padding(.top, 32)
            Button(action: onSecondary) {
                Text(secondary.uppercased())
                    .font(UVVAFont.sans(9.5, .semibold))
                    .tracking(2.85)
                    .opacity(0.8)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .overlay { Capsule().strokeBorder(NotePalette.ink.opacity(0.35), lineWidth: 0.5) }
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
        .foregroundStyle(NotePalette.ink)
        .padding(.horizontal, 26)
        .padding(.top, 28)
        .presentationDetents([.height(330)])
        .presentationDragIndicator(.visible)
        .presentationBackground(NotePalette.paper)
        .presentationCornerRadius(28)
    }
}
#endif
