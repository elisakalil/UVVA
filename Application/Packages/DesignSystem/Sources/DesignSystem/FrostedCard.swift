import SwiftUI

/// Frosted glass, the base material of the app (FrostedCard). The glass itself is `FrostedGlass`.
public struct FrostedCard<Content: View>: View {
    var radius: CGFloat
    var padding: CGFloat
    /// See `FrostedGlass.pinsPhoto`.
    var pinsPhoto: Bool
    var cachesRim: Bool
    var content: Content

    public init(radius: CGFloat = UVVARadius.card, padding: CGFloat = UVVASpace.card, pinsPhoto: Bool = false,
                cachesRim: Bool = false, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.padding = padding
        self.pinsPhoto = pinsPhoto
        self.cachesRim = cachesRim
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { FrostedGlass(radius: radius, pinsPhoto: pinsPhoto, cachesRim: cachesRim) }
    }
}
