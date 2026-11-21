import SwiftUI

/// The photos of the design system (assets/Backgrounds).
public enum UVVAPhoto {
    /// bg1: the vineyard behind full pages and inside share cards.
    public static var background: Image { Image(GlassTextures.photoName, bundle: .module) }
    /// bg2: only the hills, behind the You tab and Friends. The You panels carry bg1; the Friends glass shows the hills.
    public static var hills: Image { Image("BackgroundHills", bundle: .module) }
}
