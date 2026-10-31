import SwiftUI

/// Title of a group of cards, sitting on the photo above them (APRENDER, PALAVRA DO DIA).
public struct SectionLabel: View {
    var text: String

    public init(text: String) { self.text = text }

    public var body: some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(9, .semibold))
            .tracking(3.6)
            .foregroundStyle(UVVAColor.cream84)
            .padding(.top, 22)
    }
}
