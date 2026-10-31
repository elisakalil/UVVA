import SwiftUI

/// Colour tokens from the UVVA design system (tokens.json).
public enum UVVAColor {
    public static let moss = Color(hex: 0x333D28)
    public static let mossDeep = Color(hex: 0x2B3126)
    public static let night = Color(hex: 0x1B2015)
    public static let sky = Color(hex: 0xA9CFDC)
    /// Text, icons and lines: the same light ink as the logo.
    public static let cream = Color(hex: 0xF6F4EE)
    public static let logoInk = cream
    /// The warmer cream behind filled buttons and selected chips.
    public static let creamFill = Color(hex: 0xF3ECDE)
    public static let ink = Color(hex: 0x22271C)
    public static let grape = Color(hex: 0x9D8FF0)
    public static let burgundy = Color(hex: 0x4B1D2D)
    public static let cream84 = cream.opacity(0.84)
    public static let cream60 = cream.opacity(0.6)
    public static let cream14 = cream.opacity(0.14)
    public static let glassEdge = Color.white.opacity(0.22)
}
