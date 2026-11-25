import Foundation

/// Reads the wine's facts out of the text of its two label photos (CELLAR-R17), without a network: the vintage,
/// the alcohol, the type, the appellation, region and country, the grapes, the lines that could be the name
/// and the producer, and what certifies it: the appellation's category, the legal term and the medals (CELLAR-R30).
/// What it cannot tell stays nil, for the catalog lookup or the person to fill in.
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

        let designation = CertificationKeywords.designation(in: text.front.map(\.text).joined(separator: " "))
            ?? CertificationKeywords.designation(in: text.back.map(\.text).joined(separator: " "))
        let known = Set(([appellation, region, country, designation].compactMap { $0 } + grapes).flatMap(WineText.tokens))
        let titles = titleLines(text.front, known: known)
        let producer = producerLine(front: text.front, back: text.back, titles: titles)
        let name = titles.first { WineText.tokens($0) != WineText.tokens(producer ?? "") }

        return LabelFacts(name: name, producer: producer, vintage: vintage(in: lines, currentYear: currentYear),
                          type: type, appellation: certified(lines, name: appellation ?? region) ?? appellation,
                          region: region, country: country, grapes: grapes, alcohol: alcohol(in: lines),
                          titleLines: titles, serving: serving(in: lines), designation: designation,
                          awards: awards(in: lines, currentYear: currentYear), oakAging: oakAging(in: lines),
                          oakWoods: oakWoods(in: lines))
    }

    // MARK: Certification (CELLAR-R30)

    /// The appellation with its category, from the first line that names one: "Douro DOC", "Vinho Regional Lisboa".
    /// Without a name read elsewhere, the line as printed.
    private static func certified(_ lines: [LabelLine], name: String?) -> String? {
        for line in lines {
            guard let found = CertificationKeywords.category(in: line.text) else { continue }
            // "Vinho Regional Alentejano" already says its category.
            if let name, CertificationKeywords.split(name).category != nil { return name }
            guard let name else {
                let words = line.text.split(whereSeparator: \.isWhitespace)
                return words.count <= 8 ? line.text.trimmingCharacters(in: .whitespaces) : found.category
            }
            let categoryFirst = ["Vinho Regional", "Vin de Pays", "Vino de la Tierra", "Landwein", "IG"]
            return categoryFirst.contains(found.category) ? "\(found.category) \(name)" : "\(name) \(found.category)"
        }
        return nil
    }

    /// Medals and critics' scores: a competition or critic the line names, with the medal or score and the year on
    /// it or the lines around it on the same label. A medal word alone is not enough ("golden colour").
    static func awards(in lines: [LabelLine], currentYear: Int) -> [WineAward] {
        var awards: [WineAward] = []
        for index in lines.indices {
            guard let source = CertificationKeywords.source(in: lines[index].text) else { continue }
            // The lines around it on the same label: a seal does not run from the front onto the back.
            let around = [index - 1, index, index + 1]
                .filter { lines.indices.contains($0) && lines[$0].side == lines[index].side }
                .map { lines[$0].text }.joined(separator: " ")
            let year = WineText.tokens(around).compactMap { Int($0) }.first { (1990...currentYear).contains($0) }
            if source.isCritic {
                let score = /([0-9]{2,3})\s*(?:pts|points|pontos|punti|puntos|pt|p)\b/
                guard let match = around.lowercased().firstMatch(of: score), let points = Int(match.1),
                      (80...100).contains(points) else { continue }
                awards.append(WineAward(competition: source.name, points: points, year: year))
            } else if let medal = CertificationKeywords.medal(in: around) {
                awards.append(WineAward(competition: source.name, medal: medal, year: year))
            }
        }
        return [WineAward]().adding(awards)
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

    // MARK: Wood (CELLAR-R23)

    /// The words around months in wood: "estagiou 12 meses em barricas de carvalho", "aged 18 months in oak".
    private static let woodWords: Set<String> = [
        "barrica", "barricas", "barril", "barris", "carvalho", "madeira", "tonel", "toneis", "oak", "barrel",
        "barrels", "cask", "casks", "barrique", "barriques", "fut", "futs", "chene", "bois", "botte", "botti",
        "rovere", "legno", "roble", "eiche", "holzfass", "fass"
    ]

    /// The months in wood a label prints, the first it names; "sem madeira" and "unoaked" are none.
    static func oakAging(in lines: [LabelLine]) -> OakAging? {
        let folded = WineText.folded(lines.map(\.text).joined(separator: " "))
        let unoaked = [" sem madeira ", " sem estagio em madeira ", " unoaked ", " no oak ", " sans bois ",
                       " senza legno ", " sin madera ", " inox ", " stainless steel "]
        if unoaked.contains(where: folded.contains) { return OakAging.none }
        let tokens = WineText.tokens(lines.map(\.text).joined(separator: " "))
        let monthWords: Set<String> = ["meses", "mes", "months", "month", "mois", "mesi", "monate", "monaten"]
        let yearWords: Set<String> = ["anos", "ano", "years", "year", "ans", "anni", "jahre", "jahren"]
        for index in tokens.indices {
            guard let count = Int(tokens[index]), (1...120).contains(count), index + 1 < tokens.count else { continue }
            let unit = tokens[index + 1]
            let months = monthWords.contains(unit) ? count : yearWords.contains(unit) && count <= 10 ? count * 12 : nil
            guard let months else { continue }
            // The wood within the next few words: "12 meses em barricas", "18 months in French oak".
            let after = tokens[(index + 2)..<min(tokens.count, index + 8)]
            if after.contains(where: woodWords.contains) { return OakAging(months: months) }
        }
        return nil
    }

    /// The woods the label names, in `OakWood.all`'s spelling.
    static func oakWoods(in lines: [LabelLine]) -> [String] {
        let folded = WineText.folded(lines.map(\.text).joined(separator: " "))
        return OakWood.phrases.filter { folded.contains(" \($0.phrase) ") }.map(\.wood).adding([])
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
        if let value = labeledAlcohol(in: lines, within: plausible) { return value }
        let texts = lines.map { $0.text.lowercased().folding(options: .diacriticInsensitive, locale: nil) }
        let bare = /([0-9]{1,2}(?:[.,][0-9]{1,2})?)\s*%\s*([a-z]*)/
        for text in texts {
            for match in text.matches(of: bare) where match.output.2.isEmpty {
                if let value = number(match.output.1), plausible.contains(value) { return value }
            }
        }
        return nil
    }

    /// The first percentage in `range` with an alcohol word around it, "13,5% vol", "Alc. 14% by vol.": a bare
    /// percentage may be a grape's share or a nutrient's.
    static func labeledAlcohol(in lines: [LabelLine], within range: ClosedRange<Double>) -> Double? {
        let withWord = /(?:alc|alcohol|alcool|grad)[^0-9%]{0,12}([0-9]{1,2}(?:[.,][0-9]{1,2})?)\s*%|([0-9]{1,2}(?:[.,][0-9]{1,2})?)\s*%\s*(?:vol|alc|abv|v\/v|by vol)/
        for line in lines {
            let text = line.text.lowercased().folding(options: .diacriticInsensitive, locale: nil)
            for match in text.matches(of: withWord) {
                if let value = (match.output.1 ?? match.output.2).flatMap(number), range.contains(value) { return value }
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
        // Each label read as one text, so the producer can sit on the line after the phrase, and a phrase given in
        // several languages ("engarrafado por | bottled by | mis en bouteille par") can wrap.
        for side in [front, back] where !side.isEmpty {
            let text = side.map(\.text).joined(separator: "\n")
            let folded = WineText.folded(text)
            for phrase in bottledByLongestFirst {
                guard let range = folded.range(of: " \(phrase) ") else { continue }
                // Keep the original spelling: drop as many words from the text as the phrase took.
                let skipped = WineText.tokens(String(folded[..<range.upperBound])).count
                let rest = droppingBottledBy(droppingWords(skipped, from: text[...]))
                let producer = rest.split(whereSeparator: { ",.;|\n".contains($0) }).first
                    .map { $0.trimmingCharacters(in: .whitespaces) } ?? ""
                if producer.filter(\.isLetter).count >= 3 { return producer }
            }
        }
        return nil
    }

    private static let bottledByLongestFirst = LabelKeywords.bottledBy.sorted { $0.count > $1.count }

    /// The text from its word after the first `count`, as `WineText.tokens` counts words: "|", "·" and line
    /// breaks are not words, so they are skipped, not counted.
    private static func droppingWords(_ count: Int, from text: Substring) -> Substring {
        var seen = 0
        var inWord = false
        for index in text.indices {
            let isWordCharacter = !WineText.tokens(String(text[index])).isEmpty
            if isWordCharacter, !inWord {
                if seen == count { return text[index...] }
                seen += 1
            }
            inWord = isWordCharacter
        }
        return text[text.endIndex...]
    }

    /// The text after the "Bottled by" phrases it starts with: "bottled by | mis en bouteille par Ravasqueira"
    /// → "Ravasqueira".
    private static func droppingBottledBy(_ text: Substring) -> Substring {
        var rest = droppingWords(0, from: text)
        while let phrase = bottledByLongestFirst.first(where: { WineText.folded(String(rest)).hasPrefix(" \($0) ") }) {
            rest = droppingWords(WineText.tokens(phrase).count, from: rest)
        }
        return rest
    }
}
