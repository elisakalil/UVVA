import Foundation

/// The headings of a wine list and the type each one says (WINELIST-R04): "Tintos" is red, "Bubbles" sparkling.
public enum WineListSection {
    /// Folded heading words to the type they say, in the languages UVVA reads.
    static let keywords: [String: String] = [
        "tinto": "Red", "tintos": "Red", "red": "Red", "reds": "Red", "rouge": "Red", "rouges": "Red",
        "rosso": "Red", "rossi": "Red", "rotwein": "Red", "rotweine": "Red",
        "branco": "White", "brancos": "White", "white": "White", "whites": "White", "blanc": "White",
        "blancs": "White", "bianco": "White", "bianchi": "White", "blanco": "White", "blancos": "White",
        "weisswein": "White", "weissweine": "White",
        "rose": "Rosé", "roses": "Rosé", "rosado": "Rosé", "rosados": "Rosé", "rosato": "Rosé", "rosati": "Rosé",
        "espumante": "Sparkling", "espumantes": "Sparkling", "sparkling": "Sparkling", "champagne": "Sparkling",
        "champagnes": "Sparkling", "spumante": "Sparkling", "spumanti": "Sparkling", "cava": "Sparkling",
        "cavas": "Sparkling", "bubbles": "Sparkling", "espumosos": "Sparkling", "frisante": "Sparkling",
        "fortificado": "Fortified", "fortificados": "Fortified", "fortified": "Fortified", "generoso": "Fortified",
        "generosos": "Fortified", "porto": "Fortified", "port": "Fortified", "madeira": "Fortified",
        "sobremesa": "Fortified", "dessert": "Fortified", "jerez": "Fortified", "sherry": "Fortified"
    ]

    /// Words that may stand around a heading without making it a wine: "Vinhos tintos", "Red wines".
    static let filler: Set<String> = [
        "vinho", "vinhos", "wine", "wines", "vin", "vins", "vino", "vini", "vinos", "de", "do", "da", "the", "our",
        "nossos", "nossa", "nosso", "e", "and", "et", "y", "carta", "list", "por", "copo", "garrafa", "glass",
        "bottle", "taca", "garrafas", "copos", "glasses", "bottles", "preco", "price", "precos", "prices"
    ]

    /// The type a heading says, nil when the line is not a heading: every word is a type or a filler word, and one
    /// of them is a type. "Tinto Reserva do Produtor" is a wine, not a heading.
    public static func type(of line: String) -> String? {
        let words = WineText.tokens(line)
        guard !words.isEmpty, words.count <= 4 else { return nil }
        var type: String?
        for word in words {
            if let found = keywords[word] {
                type = type ?? found
            } else if !filler.contains(word) {
                return nil
            }
        }
        return type
    }
}

extension WineListSection {
    /// A line made only of the words around the wines, "Copo · Garrafa", "Our wines": neither a wine nor a heading.
    public static func isFiller(_ line: String) -> Bool {
        let words = WineText.tokens(line).filter { Int($0) == nil }
        return !words.isEmpty && words.allSatisfy { filler.contains($0) }
    }
}
