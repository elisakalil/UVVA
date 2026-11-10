import DesignSystem
import SwiftUI

/// HOME-R10c: while a card that follows the map is read again, it keeps its size, its content steps back and a
/// curtain of grapes runs down it; when the new content is in, the curtain fades slowly as the content comes back.
/// The card's own content takes `MatchCurtain.contentOpacity`, so the glass stays while the content fades.
struct MatchCurtain: ViewModifier {
    var isLoading: Bool
    var radius: CGFloat = UVVARadius.hero

    /// The curtain comes in gently and leaves slower still.
    static let fadeIn = Animation.easeOut(duration: 0.6)
    static let fadeOut = Animation.easeInOut(duration: 1.4)

    static func contentOpacity(_ isLoading: Bool) -> Double { isLoading ? 0 : 1 }

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

extension View {
    func matchCurtain(_ isLoading: Bool, radius: CGFloat = UVVARadius.hero) -> some View {
        modifier(MatchCurtain(isLoading: isLoading, radius: radius))
    }
}
