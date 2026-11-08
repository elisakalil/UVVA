import Foundation

/// Wine text reduced to what can be compared: lower case, no accents, only ASCII letters and digits.
public enum WineText {
    /// "Château Musar Rouge 2016" → ["chateau", "musar", "rouge", "2016"]. Any other character, Greek and
    /// Cyrillic letters included, separates words, as in the packed wineKeys.
    public static func tokens(_ text: String) -> [String] {
        let decomposed = text.lowercased().decomposedStringWithCompatibilityMapping
        var tokens: [String] = []
        var current = ""
        for scalar in decomposed.unicodeScalars {
            if isMark(scalar) { continue }
            if scalar.isASCII, scalar.properties.isAlphabetic || ("0"..."9").contains(scalar) {
                current.unicodeScalars.append(scalar)
            } else if !current.isEmpty {
                tokens.append(current)
                current = ""
            }
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }

    /// The tokens joined by single spaces, padded with one on each side, so a phrase is found as whole words
    /// with `contains(" \(phrase) ")`.
    public static func folded(_ text: String) -> String {
        " " + tokens(text).joined(separator: " ") + " "
    }

    /// The tokens that tell one wine from another: no digits, no single letters, no "de", "the" or "vinho".
    public static func significantTokens(_ text: String) -> Set<String> {
        Set(tokens(text).filter { $0.count > 1 && Int($0) == nil && !connectives.contains($0) })
    }

    private static let connectives: Set<String> = [
        "de", "do", "da", "dos", "das", "di", "del", "della", "dei", "du", "des", "la", "le", "les", "el", "los",
        "the", "of", "and", "et", "e", "y", "und", "von", "vin", "vino", "vinho", "wine", "wein"
    ]

    /// Accents and other combining marks, which the fold drops, as Python's `unicodedata.combining` does.
    private static func isMark(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.properties.generalCategory {
        case .nonspacingMark, .spacingMark, .enclosingMark: true
        default: false
        }
    }
}
