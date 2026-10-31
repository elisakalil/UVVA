import SwiftUI

/// Where the full-page photo sits on screen, so each piece of glass can show the part of it right behind.
/// Set once at the root; glass without it falls back to the system material.
extension EnvironmentValues {
    @Entry public var backdropFrame: CGRect? = nil
}
