import SwiftUI

/// Small tracked caption under a title (NAVARRA, SPAIN).
public struct Caption: View {
    var text: String
    var color: Color

    /// `color` defaults to the faint cream; panes over a bright photo (the Home cards) pass a stronger one.
    public init(text: String, color: Color = UVVAColor.cream60) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(8, .semibold))
            .tracking(2.6)
            .foregroundStyle(color)
    }
}
