import SwiftUI

public struct Eyebrow: View {
    var text: String
    var color: Color

    /// `color` defaults to the soft cream; panes over a bright photo (the Home cards) pass full cream to stay legible.
    public init(text: String, color: Color = UVVAColor.cream84) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(9, .regular))
            .tracking(1.8)
            .foregroundStyle(color)
    }
}
