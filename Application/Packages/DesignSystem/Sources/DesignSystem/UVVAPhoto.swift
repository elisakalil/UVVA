import SwiftUI

/// The photos of the design system (assets/Backgrounds).
public enum UVVAPhoto {
    /// bg1: the vineyard behind full pages and inside share cards.
    public static var background: Image { Image(GlassTextures.photoName, bundle: .module) }
    /// bg2: only the hills, behind the You tab. Its glass still shows bg1.
    public static var hills: Image { Image("BackgroundHills", bundle: .module) }
}
