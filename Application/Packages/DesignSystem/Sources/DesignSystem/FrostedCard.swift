import SwiftUI

/// Frosted glass, the base material of the app (FrostedCard). The glass itself is `FrostedGlass`.
public struct FrostedCard<Content: View>: View {
    var radius: CGFloat
    var padding: CGFloat
    var content: Content

    public init(radius: CGFloat = UVVARadius.card, padding: CGFloat = UVVASpace.card,
                @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { FrostedGlass(radius: radius) }
    }
}
