import SwiftUI

/// Frosted glass, the base material of the app (FrostedCard). The glass itself is `FrostedGlass`.
public struct FrostedCard<Content: View>: View {
    var radius: CGFloat
    var padding: CGFloat
    /// See `FrostedGlass.pinsPhoto`.
    var pinsPhoto: Bool
    var cachesRim: Bool
    var content: Content

    /// The card is being read again (HOME-R10c): its content steps back under the grape curtain.
    @Environment(\.cardIsLoading) private var isLoading

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
            // A card inside the card is hidden with it: one curtain is enough.
            .environment(\.cardIsLoading, false)
            .cardContentHidden(isLoading)
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { FrostedGlass(radius: radius, pinsPhoto: pinsPhoto, cachesRim: cachesRim) }
            .cardCurtain(isLoading, radius: radius)
    }
}
