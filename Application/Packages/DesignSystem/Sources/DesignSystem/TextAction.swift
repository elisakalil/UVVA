import SwiftUI

/// A quiet action written as caps text under a main button ("Read it again", "Not now").
public struct TextAction: View {
    var title: String
    var opacity: Double
    var action: () -> Void

    public init(_ title: String, opacity: Double = 0.45, action: @escaping () -> Void) {
        self.title = title
        self.opacity = opacity
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(UVVAFont.sans(10))
                .tracking(2)
                .foregroundStyle(UVVAColor.creamFill.opacity(opacity))
                .padding(.vertical, 8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
