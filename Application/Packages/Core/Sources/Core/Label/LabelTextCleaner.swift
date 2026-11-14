import Foundation

/// The label's text with what says nothing of the wine taken out, before the parser and the model read it
/// (CELLAR-R17): the allergen lines repeated in every language, the nutrition table, lot and bar codes, scraps of a
/// letter or two, and lines another line already says. A back label scanned in many frames is mostly these.
public enum LabelTextCleaner {
    /// What the model on the phone is given of the back label, in characters: its context window is small, and a
    /// label that overflows it comes back almost empty.
    public static let modelBackCharacters = 1800

    /// Words of the lines that are never about the wine, folded: allergens, the nutrition declaration, codes.
    static let boilerplateWords: Set<String> = [
        "contains", "contient", "contem", "enthalt", "contiene", "indeholder", "inneholder", "zawiera",
        "sulphites", "sulfites", "sulfitos", "sulfiti", "sulfiter", "sulphite", "sulfite", "siarczyny",
        "allergens", "nutritional", "nutritionnelle", "nutricional", "nutrizionale", "declaration", "declaracao",
        "dichiarazione", "ingredients", "ingredientes", "ingredienti", "zutaten", "kj", "kcal", "energia", "energy",
        "energie", "lote", "lot", "batch", "www", "http", "https", "100ml"
    ]

    /// The long boilerplate words, which a camera misspells ("Beclaration", "Sullites") but still reads close.
    private static let longBoilerplate = boilerplateWords.filter { $0.count >= 8 }

    public static func clean(_ text: LabelText) -> LabelText {
        let kept = text.lines.filter { !isBoilerplate($0.text) }
        return LabelText(withoutRepeats(kept))
    }

    /// The text for the model: the front whole, and of the back its surest lines up to `backCharacters`, in the
    /// label's order.
    public static func forModel(_ text: LabelText, backCharacters: Int = modelBackCharacters) -> LabelText {
        let back = text.back.enumerated()
        var chosen = Set<Int>()
        var used = 0
        for (index, line) in back.sorted(by: { lhs, rhs in
            lhs.element.confidence == rhs.element.confidence
                ? lhs.element.text.count > rhs.element.text.count
                : lhs.element.confidence > rhs.element.confidence
        }) where used + line.text.count <= backCharacters {
            chosen.insert(index)
            used += line.text.count + 1
        }
        return LabelText(text.front + back.filter { chosen.contains($0.offset) }.map(\.element))
    }

    static func isBoilerplate(_ line: String) -> Bool {
        // "Contains Sulphites / Contient des Sulfites / Enthält Sulfite": the same line in every language.
        if line.filter({ $0 == "/" }).count >= 2 { return true }
        let words = WineText.tokens(line)
        let letters = line.filter(\.isLetter).count
        let digits = line.filter(\.isNumber).count
        // "JA", "64", "• ne": too little to be anything.
        if letters + digits < 3 { return true }
        // "SYY 7481694", "604422": lot and bar codes. A year, "2023", stays.
        if letters <= 3, digits >= 5 { return true }
        if words.contains(where: boilerplateWords.contains) { return true }
        // "E/100ml", "8/100ml".
        if line.lowercased().contains("100ml") || line.lowercased().contains("100 ml") { return true }
        return words.contains { word in
            word.count >= 7 && longBoilerplate.contains { known in
                abs(known.count - word.count) <= 2 && LabelScan.distance(Array(word.utf8), Array(known.utf8),
                                                                          limit: 2) <= 2
            }
        }
    }

    /// Each line once: a line all of whose words another line of the same side says, in the same order, goes, and
    /// the line that stays is as sure as the surer of the two.
    static func withoutRepeats(_ lines: [LabelLine]) -> [LabelLine] {
        let folded = lines.map { WineText.folded($0.text) }
        var kept = lines
        var dropped = Set<Int>()
        for index in lines.indices where folded[index].count > 2 {
            let longer = lines.indices.first { other in
                other != index && !dropped.contains(other) && lines[other].side == lines[index].side
                    && folded[other].count >= folded[index].count && folded[other].contains(folded[index])
                    && (folded[other] != folded[index] || other < index)
            }
            if let longer {
                dropped.insert(index)
                kept[longer].confidence = max(kept[longer].confidence, lines[index].confidence)
            }
        }
        return kept.indices.filter { !dropped.contains($0) }.map { kept[$0] }
    }
}
