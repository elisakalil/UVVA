import DesignSystem
import SwiftUI

/// The few colours only the Cellar uses, from its artboard.
enum CellarPalette {
    /// The warm rule between the covers and above the lists.
    static let rule = Color(hex: 0xE2D5BA).opacity(0.7)
    /// Behind a cover with no photo.
    static let coverGround = UVVAColor.ink
    /// The 58% veil over the photos.
    static let veil = Color(hex: 0x0E130A).opacity(0.58)
}
