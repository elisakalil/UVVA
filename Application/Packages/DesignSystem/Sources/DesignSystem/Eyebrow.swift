import SwiftUI

public struct Eyebrow: View {
    var text: String

    public init(text: String) { self.text = text }

    public var body: some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(9, .regular))
            .tracking(1.8)
            .foregroundStyle(UVVAColor.cream84)
    }
}
