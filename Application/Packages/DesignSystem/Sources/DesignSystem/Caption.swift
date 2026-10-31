import SwiftUI

/// Small tracked caption under a title (NAVARRA, SPAIN).
public struct Caption: View {
    var text: String

    public init(text: String) { self.text = text }

    public var body: some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(8, .semibold))
            .tracking(2.6)
            .foregroundStyle(UVVAColor.cream60)
    }
}
