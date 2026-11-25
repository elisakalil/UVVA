import SwiftUI

public extension EnvironmentValues {
    /// True while `ShareScreen` draws a card into the picture that is shared or saved. The picture is square-cornered:
    /// rounded corners on screen would come out transparent, and show white in other apps.
    @Entry var isRenderingShareImage = false
}

public extension View {
    /// The card's rounded corners on screen; none in the shared picture (`isRenderingShareImage`).
    func shareCardCorners(_ radius: CGFloat, style: RoundedCornerStyle = .circular) -> some View {
        modifier(ShareCardCorners(radius: radius, style: style))
    }
}

private struct ShareCardCorners: ViewModifier {
    var radius: CGFloat
    var style: RoundedCornerStyle
    @Environment(\.isRenderingShareImage) private var isRendering

    func body(content: Content) -> some View {
        content.clipShape(RoundedRectangle(cornerRadius: isRendering ? 0 : radius, style: style))
    }
}
