import SwiftUI

/// The engraved grape bunches of the Splash, Find friends and Contacts (assets/Illustrations).
/// They are template images: draw them in cream.
public enum UVVAIllustration {
    public static let grapeCount = 7

    /// 1...7, in the order of the Splash.
    public static func grape(_ number: Int) -> Image {
        Image("Grape\(min(max(number, 1), grapeCount))", bundle: .module).renderingMode(.template)
    }

    /// Three hands around a bunch, in an oval: the UVVA seal on every certificate card.
    public static var certificateSeal: Image {
        Image("UVVACertificateSeal", bundle: .module).renderingMode(.template)
    }

    /// The engraved plate beside "The perfect table" on the Home hero.
    public static var plate: Image {
        Image("Plate", bundle: .module).renderingMode(.template)
    }

    /// A glass of red drawn in ink: the line on why a wine suits the user's map.
    public static var wineglass: Image {
        Image("Wineglass", bundle: .module).renderingMode(.template)
    }

    /// A map pin drawn in ink: the line on what the user knows of a wine's region.
    public static var pin: Image {
        Image("Pin", bundle: .module).renderingMode(.template)
    }

    /// Three figures around a table: the Friends button that starts a group table.
    public static var table: Image {
        Image("Table", bundle: .module).renderingMode(.template)
    }
}
