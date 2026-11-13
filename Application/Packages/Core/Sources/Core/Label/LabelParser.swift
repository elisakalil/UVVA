import Foundation

/// Reads the wine's facts out of the text of its two label photos (CELLAR-R17), without a network: the vintage,
/// the alcohol, the type, the appellation, region and country, the grapes, and the lines that could be the name
/// and the producer. What it cannot tell stays nil, for the catalog lookup or the person to fill in.
public enum LabelParser {
    /// The vintages a label can show: older years are founding dates or solera years.
    static let earliestVintage = 1900

    public static func parse(_ text: LabelText, vocabulary: LabelVocabulary, currentYear: Int) -> LabelFacts {
        let lines = text.front + text.back
        var remaining = WineText.folded(lines.map(\.text).joined(separator: " "))

        let appellation = longestMatch(in: &remaining, among: Set(vocabulary.appellationRegions.keys)
            .union(vocabulary.appellationTypes.keys))
        var grapes: [String] = []
        while let grape = longestMatch(in: &remaining, among: vocabulary.grapeTypes.keys) {
            grapes.append(grape)
        }
        let region = appellation.flatMap { vocabulary.appellationRegions[$0] }
            ?? longestMatch(in: &remaining, among: vocabulary.regionCountries.keys)
        let country = longestMatch(in: &remaining, among: vocabulary.countries)
            ?? localCountry(in: remaining)
            ?? region.flatMap { vocabulary.regionCountries[$0] }

        let type = keywordType(in: text, ignoring: grapes)
            ?? appellation.flatMap { vocabulary.appellationTypes[$0] }
            ?? grapes.lazy.compactMap { vocabulary.grapeTypes[$0] }.first

        let known = Set(([appellation, region, country].compactMap { $0 } + grapes).flatMap(WineText.tokens))
        let titles = titleLines(text.front, known: known)
        let producer = producerLine(front: text.front, back: text.back, titles: titles)
        let name = titles.first { WineText.tokens($0) != WineText.tokens(producer ?? "") }

        return LabelFacts(name: name, producer: producer, vintage: vintage(in: lines, currentYear: currentYear),
                          type: type, appellation: appellation, region: region, country: country, grapes: grapes,
                          alcohol: alcohol(in: lines), titleLines: titles, serving: serving(in: lines))
    }

    // MARK: Names from the catalog

    /// The longest name of `names` found as whole words in `text`, which is then blanked out, so "Cabernet
    /// Sauvignon" is not read again as "Sauvignon" and "Sauvignon Blanc" does not make the wine White.
    /// Names under four letters are skipped: too many false hits.
    private static func longestMatch(in text: inout String, among names: some Collection<String>) -> String? {
        let candidates = names
            .map { (name: $0, folded: WineText.folded($0)) }
            .filter { $0.folded.filter(\.isLetter).count >= 4 && text.contains($0.folded) }
        guard let best = candidates.max(by: { lhs, rhs in
            lhs.folded.count == rhs.folded.count ? lhs.name > rhs.name : lhs.folded.count < rhs.folded.count
        }) else { return nil }
        text = text.replacingOccurrences(of: best.folded, with: " ")
        return best.name
    }

    /// "Italia", "España": the country as a label from there names it.
    private static func localCountry(in text: String) -> String? {
        LabelKeywords.countryNames
            .sorted { $0.key.count > $1.key.count }
            .first { text.contains(" \($0.key) ") }?
            .value
    }

    // MARK: Type

    /// The first type whose word is on the label, grape names left out ("Sauvignon Blanc" says nothing of colour).
    private static func keywordType(in text: LabelText, ignoring grapes: [String]) -> String? {
        var folded = WineText.folded(text.lines.map(\.text).joined(separator: " "))
        for grape in grapes {
            folded = folded.replacingOccurrences(of: WineText.folded(grape), with: " ")
        }
        return LabelKeywords.types.first { entry in
            entry.words.contains { folded.contains(" \($0) ") }
        }?.type
    }

    // MARK: Vintage and alcohol

    /// The first plausible year, front before back, skipping founding dates ("Since 1887").
    private static func vintage(in lines: [LabelLine], currentYear: Int) -> Int? {
        for line in lines {
            let tokens = WineText.tokens(line.text)
            for (index, token) in tokens.enumerated() {
                guard token.count == 4, let year = Int(token), (earliestVintage...currentYear).contains(year) else {
                    continue
                }
                let before = tokens[max(0, index - 2)..<index]
                if before.contains(where: LabelKeywords.foundedWords.contains) { continue }
                return year
            }
        }
        return nil
    }

    /// "Serve at 16-18°C", "Servir a 16 – 18 ºC", "16°/18°C": two temperatures a wine is served at, with a degree
    /// sign; a single one, "Serve at 8 °C", makes a range of one degree.
    static func serving(in lines: [LabelLine]) -> ClosedRange<Int>? {
        let plausible = 4...22
        let text = lines.map(\.text).joined(separator: " ")
        let range = /([0-9]{1,2})\s*[°º]?\s*C?\s*(?:-|–|—|\/|a|to|à|bis|e)\s*([0-9]{1,2})\s*[°º]\s*C?/
        if let match = text.firstMatch(of: range), let low = Int(match.1), let high = Int(match.2),
           plausible.contains(low), plausible.contains(high), low <= high {
            return low...high
        }
        let single = /([0-9]{1,2})\s*[°º]\s*C/
        if let match = text.firstMatch(of: single), let degrees = Int(match.1), plausible.contains(degrees) {
            return degrees...degrees
        }
        return nil
    }

    /// "13,5% vol", "Alc. 14% by vol.": first a percentage with an alcohol word around it; failing that, any
    /// percentage between 5 and 23 on a line without a grape share ("85% Syrah").
    private static func alcohol(in lines: [LabelLine]) -> Double? {
        let plausible = 5.0...23.0
        let texts = lines.map { $0.text.lowercased().folding(options: .diacriticInsensitive, locale: nil) }
        let withWord = /(?:alc|alcohol|alcool|grad)[^0-9%]{0,12}([0-9]{1,2}(?:[.,][0-9]{1,2})?)\s*%|([0-9]{1,2}(?:[.,][0-9]{1,2})?)\s*%\s*(?:vol|alc|abv|v\/v|by vol)/
        for text in texts {
            for match in text.matches(of: withWord) {
                let raw = match.output.1 ?? match.output.2
                if let value = raw.flatMap(number), plausible.contains(value) { return value }
            }
        }
        let bare = /([0-9]{1,2}(?:[.,][0-9]{1,2})?)\s*%\s*([a-z]*)/
        for text in texts {
            for match in text.matches(of: bare) where match.output.2.isEmpty {
                if let value = number(match.output.1), plausible.contains(value) { return value }
            }
        }
        return nil
    }

    private static func number(_ text: Substring) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }

    // MARK: Name and producer

    /// The front lines that could name the wine, biggest type first: lines with three letters or more that are not
    /// only generic words, numbers, or a grape, appellation, region or country already read.
    private static func titleLines(_ front: [LabelLine], known: Set<String>) -> [String] {
        front
            .enumerated()
            .sorted { lhs, rhs in
                lhs.element.height == rhs.element.height ? lhs.offset < rhs.offset : lhs.element.height > rhs.element.height
            }
            .map { $0.element.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { line in
                let tokens = WineText.tokens(line)
                guard line.filter(\.isLetter).count >= 3, !line.contains("%") else { return false }
                return tokens.contains { token in
                    Int(token) == nil && !LabelKeywords.generic.contains(token) && !known.contains(token)
                        && !LabelKeywords.types.contains { $0.words.contains(token) }
                }
            }
            .reduce(into: [String]()) { lines, line in
                if !lines.contains(where: { WineText.tokens($0) == WineText.tokens(line) }) { lines.append(line) }
            }
    }

    /// A title line that starts like a producer ("Quinta do Crasto", "Château Musar"), or else the name after
    /// "Bottled by" on either label.
    private static func producerLine(front: [LabelLine], back: [LabelLine], titles: [String]) -> String? {
        if let marked = titles.first(where: { line in
            WineText.tokens(line).first.map(LabelKeywords.producerMarks.contains) ?? false
        }) {
            return marked
        }
        for line in front + back {
            let folded = WineText.folded(line.text)
            for phrase in LabelKeywords.bottledBy.sorted(by: { $0.count > $1.count }) {
                guard let range = folded.range(of: " \(phrase) ") else { continue }
                // Keep the original spelling: drop as many words from the line as the phrase took.
                let skipped = WineText.tokens(String(folded[..<range.upperBound])).count
                let words = line.text.split(whereSeparator: \.isWhitespace)
                let rest = words.dropFirst(skipped).joined(separator: " ")
                let producer = rest.split(whereSeparator: { ",.;".contains($0) }).first
                    .map { $0.trimmingCharacters(in: .whitespaces) } ?? ""
                if producer.filter(\.isLetter).count >= 3 { return producer }
            }
        }
        return nil
    }
}
