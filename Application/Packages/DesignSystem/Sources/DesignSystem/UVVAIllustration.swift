import SwiftUI

/// The engraved grape bunches of the Splash, Find friends and Contacts (assets/Illustrations).
/// They are template images: draw them in cream.
public enum UVVAIllustration {
    public static let grapeCount = 7

    /// 1...7, in the order of the Splash.
    public static func grape(_ number: Int) -> Image {
        Image("Grape\(min(max(number, 1), grapeCount))", bundle: .module).renderingMode(.template)
    }

    /// The engraved plate beside "The perfect table" on the Home hero.
    public static var plate: Image {
        Image("Plate", bundle: .module).renderingMode(.template)
    }
}
