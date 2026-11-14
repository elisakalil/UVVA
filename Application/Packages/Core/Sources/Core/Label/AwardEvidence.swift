import Foundation

/// When a medal or score read off a label is worth showing (CELLAR-R30). The catalog has no awards, so every award
/// comes from a label: a competition UVVA knows counts as it is; one it does not know counts only when its name reads
/// like a competition, so camera noise ("SENTENA COM.", "POLON US II@") never becomes a trophy.
public enum AwardEvidence {
    /// Lines the text recognizer is less sure of than this do not back an award.
    static let minimumConfidence = 0.5

    /// How words of competition names begin, in the languages UVVA reads: "Concurso", "Awards", "Vinhos",
    /// "Internacional", "Sélection"…
    static let competitionStems = [
        "concour", "concurs", "concors", "competi", "wettbewerb", "award", "premi", "prix", "preis", "challenge",
        "troph", "trofe", "medal", "medail", "mondial", "mundial", "internation", "internacion", "nacional",
        "national", "nazional", "wine", "vin", "wein", "guid", "guia", "selec", "selez", "salon", "salao", "festival",
        "show", "cup", "copa", "coupe", "cata", "expo", "olymp", "decant", "feira", "fiera", "foire", "feria", "fair",
        "messe", "jury", "jurad"
    ]

    /// The characters a competition's name is written with; anything else ("@", "#", "|") is the camera's.
    private static let nameCharacters = CharacterSet.letters.union(.decimalDigits).union(.whitespaces)
        .union(CharacterSet(charactersIn: "&'’-.,()"))

    /// A competition UVVA knows, or a name that reads like one: written in letters and with a word such a name has.
    public static func isPlausible(_ award: WineAward) -> Bool {
        if CertificationKeywords.source(in: award.competition) != nil { return true }
        guard award.competition.unicodeScalars.allSatisfy(nameCharacters.contains) else { return false }
        return WineText.tokens(award.competition).contains { word in
            word.count >= 3 && competitionStems.contains { word.hasPrefix($0) }
        }
    }

    /// The award as the model on the phone gave it is in the text the camera read surely enough: the competition's
    /// words and the medal or score, on lines the recognizer was sure of. The model sorts the text; it may not add to it.
    public static func isRead(_ award: WineAward, in lines: [LabelLine]) -> Bool {
        guard isPlausible(award) else { return false }
        let sure = lines.filter { $0.confidence >= minimumConfidence }.map(\.text).joined(separator: "\n")
        let read = Set(WineText.tokens(sure))
        let folded = WineText.folded(sure)
        if let source = CertificationKeywords.source(in: award.competition) {
            guard source.aliases.contains(where: { folded.contains(" \($0) ") }) else { return false }
        } else {
            // Most of its words: the model may fix one a camera misspelt.
            let words = WineText.tokens(award.competition).filter { $0.count >= 3 }
            guard !words.isEmpty, Double(words.filter(read.contains).count) / Double(words.count) >= 0.6 else {
                return false
            }
        }
        if let medal = award.medal {
            // Any of its words, not only the first the label shows: a bottle can carry a gold and a silver.
            return CertificationKeywords.medals.contains { $0.medal == medal && folded.contains(" \($0.phrase) ") }
        }
        if let points = award.points { return read.contains(String(points)) }
        return false
    }
}

public extension WineAward {
    /// See `AwardEvidence.isPlausible`.
    var isPlausible: Bool { AwardEvidence.isPlausible(self) }
}
