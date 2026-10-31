import SwiftUI

public struct ActionLabel: View {
    var text: String

    public init(text: String) { self.text = text }

    public var body: some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(8.5, .medium))
            .tracking(2.6)
            .foregroundStyle(UVVAColor.cream)
    }
}
