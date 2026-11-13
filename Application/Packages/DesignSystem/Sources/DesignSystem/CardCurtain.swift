import SwiftUI

/// HOME-R10c: while a card is read again, it keeps its size, its content steps back and a curtain of grapes runs
/// down it; when the new content is in, the curtain fades slowly as the content comes back.
///
/// Every `FrostedCard` under `cardIsLoading` draws it on its own, so a whole screen of cards loads at once; the glass
/// stays while the content fades.
struct CardCurtain: ViewModifier {
    var isLoading: Bool
    var radius: CGFloat

    /// The curtain comes in gently and leaves slower still.
    static let fadeIn = Animation.easeOut(duration: 0.6)
    static let fadeOut = Animation.easeInOut(duration: 1.4)

    func body(content: Content) -> some View {
        content
            .overlay {
                // Only there while loading: once it has faded out, nothing is drawn or timed.
                if isLoading {
                    GrapeCurtain()
                        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                        .transition(.opacity)
                }
            }
            .allowsHitTesting(!isLoading)
            .animation(isLoading ? Self.fadeIn : Self.fadeOut, value: isLoading)
    }
}

extension EnvironmentValues {
    /// The cards below are being read again: each `FrostedCard` hides its content under the grape curtain.
    @Entry public var cardIsLoading = false
}

extension View {
    /// The grape curtain over a card of the given radius; its content is hidden with `cardContentOpacity`.
    func cardCurtain(_ isLoading: Bool, radius: CGFloat) -> some View {
        modifier(CardCurtain(isLoading: isLoading, radius: radius))
    }

    /// The content of a card under the curtain steps back entirely, and is not read out.
    func cardContentHidden(_ isLoading: Bool) -> some View {
        opacity(isLoading ? 0 : 1).accessibilityHidden(isLoading)
    }
}
