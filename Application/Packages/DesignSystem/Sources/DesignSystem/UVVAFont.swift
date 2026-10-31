import CoreText
import SwiftUI

public enum UVVAFont {
    // PostScript names inside the files: WhiteGrape.otf is "PincelElisa-Regular".
    static let whiteGrapeName = "PincelElisa-Regular"
    static let redGrapesName = "RedGrapes-Regular"

    /// Registers the fonts of this package once at launch, so no Info.plist entry is needed.
    public static func register() {
        for file in ["WhiteGrape", "RedGrapes"] {
            guard let url = Bundle.module.url(forResource: file, withExtension: "otf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    public static func whiteGrape(_ size: CGFloat) -> Font { .custom(whiteGrapeName, fixedSize: size) }
    public static func redGrapes(_ size: CGFloat) -> Font { .custom(redGrapesName, fixedSize: size) }
    /// Every weight is drawn one step heavier than named, so text holds up over the glass
    /// while the steps between styles stay the same.
    public static func sans(_ size: CGFloat, _ weight: Font.Weight = .light) -> Font {
        .system(size: size, weight: oneStepHeavier(weight))
    }

    private static func oneStepHeavier(_ weight: Font.Weight) -> Font.Weight {
        let scale: [Font.Weight] = [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]
        guard let index = scale.firstIndex(of: weight) else { return weight }
        return scale[min(index + 1, scale.count - 1)]
    }
}
