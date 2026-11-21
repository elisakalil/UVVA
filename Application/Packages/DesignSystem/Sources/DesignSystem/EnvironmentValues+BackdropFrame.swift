import SwiftUI

/// Where the full-page photo sits on screen, so each piece of glass can show the part of it right behind.
/// Set once at the root; glass without it falls back to the system material.
extension EnvironmentValues {
    @Entry public var backdropFrame: CGRect? = nil
}

/// The photo of the page, which the glass shows blurred behind it. Pages over the hills (bg2) set `.hills`, so their
/// glass shows the hills it scrolls over; everywhere else it is the vineyard (bg1).
public enum GlassPhoto: Sendable {
    case vineyard, hills
}

extension EnvironmentValues {
    @Entry public var glassPhoto: GlassPhoto = .vineyard
}
