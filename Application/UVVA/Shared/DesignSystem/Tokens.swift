import CoreText
import SwiftUI

/// Tokens from the UVVA design system (tokens.json).
enum UVVAColor {
    static let moss = Color(hex: 0x333D28)
    static let mossDeep = Color(hex: 0x2B3126)
    static let night = Color(hex: 0x1B2015)
    static let sky = Color(hex: 0xA9CFDC)
    /// Text, icons and lines: the same light ink as the logo.
    static let cream = Color(hex: 0xF6F4EE)
    static let logoInk = cream
    /// The warmer cream behind filled buttons and selected chips.
    static let creamFill = Color(hex: 0xF3ECDE)
    static let ink = Color(hex: 0x22271C)
    static let grape = Color(hex: 0x9D8FF0)
    static let cream84 = cream.opacity(0.84)
    static let cream60 = cream.opacity(0.6)
    static let cream14 = cream.opacity(0.14)
    static let glassEdge = Color.white.opacity(0.22)
}

enum UVVAFont {
    // PostScript names inside the files: WhiteGrape.otf is "PincelElisa-Regular".
    static let whiteGrapeName = "PincelElisa-Regular"
    static let redGrapesName = "RedGrapes-Regular"

    /// Registers the bundled fonts once at launch, so no Info.plist entry is needed.
    static func register() {
        for file in ["WhiteGrape", "RedGrapes"] {
            guard let url = Bundle.main.url(forResource: file, withExtension: "otf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    static func whiteGrape(_ size: CGFloat) -> Font { .custom(whiteGrapeName, fixedSize: size) }
    static func redGrapes(_ size: CGFloat) -> Font { .custom(redGrapesName, fixedSize: size) }
    /// Every weight is drawn one step heavier than named, so text holds up over the glass
    /// while the steps between styles stay the same.
    static func sans(_ size: CGFloat, _ weight: Font.Weight = .light) -> Font {
        .system(size: size, weight: oneStepHeavier(weight))
    }

    private static func oneStepHeavier(_ weight: Font.Weight) -> Font.Weight {
        let scale: [Font.Weight] = [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]
        guard let index = scale.firstIndex(of: weight) else { return weight }
        return scale[min(index + 1, scale.count - 1)]
    }
}

enum UVVASpace {
    static let gutter: CGFloat = 24
    static let inset: CGFloat = 30
    static let card: CGFloat = 20
}

enum UVVARadius {
    static let hero: CGFloat = 36
    static let card: CGFloat = 24
    static let pill: CGFloat = 100
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

/// Frosted glass, the base material of the app (FrostedCard). The glass itself is `FrostedGlass`.
struct FrostedCard<Content: View>: View {
    var radius: CGFloat = UVVARadius.card
    var padding: CGFloat = UVVASpace.card
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { FrostedGlass(radius: radius) }
    }
}

struct Eyebrow: View {
    var text: String
    var body: some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(9, .regular))
            .tracking(1.8)
            .foregroundStyle(UVVAColor.cream84)
    }
}

struct ActionLabel: View {
    var text: String
    var body: some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(8.5, .medium))
            .tracking(2.6)
            .foregroundStyle(UVVAColor.cream)
    }
}
