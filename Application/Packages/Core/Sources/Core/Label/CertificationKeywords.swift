import Foundation

/// How much an appellation category says (CELLAR-R30), from none to the top ranks.
public enum AppellationTier: Int, Comparable, Sendable {
    /// IGT, IGP, Vinho Regional: a protected origin with broad rules.
    case regional = 1
    /// DOC, AOC, DO, DAC: a protected origin with its own rules.
    case protected = 2
    /// DOCG, DOCa, Grand Cru, Premier Cru, Cru Classé: the top of a country's ladder.
    case top = 3

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// How much a legal ageing or rank term on the label says, where the wine is from (CELLAR-R30).
public enum DesignationStrength: Int, Comparable, Sendable {
    /// A word the law does not define there ("Reserve" in most countries).
    case weak = 1
    /// Ageing the law requires: Reserva or Crianza in Portugal and Spain.
    case aged = 2
    /// Long ageing and an approval the law requires: Grande Reserva, Gran Reserva, Riserva.
    case strong = 3

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// A competition or a critic whose medals and scores a bottle shows.
public struct AwardSource: Sendable {
    public enum Tier: Int, Sendable { case major = 1, known = 2 }

    public var name: String
    /// Folded spellings, longest first when matched.
    public var aliases: [String]
    public var tier: Tier
    public var isCritic: Bool
}

/// The words of a label's certification (CELLAR-R30), folded by `WineText`: appellation categories, legal terms,
/// medals and the competitions and critics behind them. Shared by the parser and the certificate.
public enum CertificationKeywords {
    // MARK: Appellation categories

    /// Folded phrase → the category as written on the card, and its tier.
    static let categories: [(phrase: String, category: String, tier: AppellationTier)] = [
        ("denominazione di origine controllata e garantita", "DOCG", .top),
        ("docg", "DOCG", .top), ("d o c g", "DOCG", .top),
        ("denominacion de origen calificada", "DOCa", .top), ("doca", "DOCa", .top), ("d o ca", "DOCa", .top),
        ("doq", "DOQ", .top),
        ("grand cru classe", "Grand Cru Classé", .top), ("grand cru", "Grand Cru", .top),
        ("premier grand cru classe", "Premier Grand Cru Classé", .top),
        ("premier cru", "Premier Cru", .top), ("1er cru", "Premier Cru", .top), ("cru classe", "Cru Classé", .top),
        ("grosse lage", "Grosse Lage", .top),
        ("denominacao de origem controlada", "DOC", .protected),
        ("denominazione di origine controllata", "DOC", .protected), ("doc", "DOC", .protected),
        ("d o c", "DOC", .protected),
        ("denominacao de origem protegida", "DOP", .protected), ("dop", "DOP", .protected),
        ("denominacion de origen protegida", "DOP", .protected),
        ("denominacion de origen", "DO", .protected), ("d o", "DO", .protected),
        ("appellation d origine controlee", "AOC", .protected), ("aoc", "AOC", .protected),
        ("appellation d origine protegee", "AOP", .protected), ("aop", "AOP", .protected),
        ("american viticultural area", "AVA", .protected),
        ("districtus austriae controllatus", "DAC", .protected), ("dac", "DAC", .protected),
        ("vqa", "VQA", .protected), ("wine of origin", "WO", .protected),
        ("pradikatswein", "Prädikatswein", .protected), ("qualitatswein", "Qualitätswein", .protected),
        ("indicazione geografica tipica", "IGT", .regional), ("igt", "IGT", .regional),
        ("indicacao geografica protegida", "IGP", .regional),
        ("indication geographique protegee", "IGP", .regional), ("igp", "IGP", .regional),
        ("vinho regional", "Vinho Regional", .regional), ("indicacao geografica", "IG", .regional),
        ("vin de pays", "Vin de Pays", .regional), ("vino de la tierra", "Vino de la Tierra", .regional),
        ("landwein", "Landwein", .regional)
    ]

    /// "Douro DOC" → ("Douro", "DOC", .protected); "Appellation Margaux Contrôlée" → ("Margaux", "AOC", .protected);
    /// "Colchagua Valley" → ("Colchagua Valley", nil). The name keeps the label's spelling.
    public static func split(_ appellation: String) -> (name: String?, category: String?, tier: AppellationTier?) {
        var words = appellation.split(whereSeparator: \.isWhitespace).map(String.init)
        let folded = words.map { WineText.tokens($0) }
        // "Appellation Margaux Contrôlée": the name sits inside the category.
        if folded.first == ["appellation"], let last = folded.last, last == ["controlee"] || last == ["protegee"],
           words.count > 2 {
            let name = words.dropFirst().dropLast().joined(separator: " ")
            return (clean(name), last == ["controlee"] ? "AOC" : "AOP", .protected)
        }
        for entry in categories.sorted(by: { $0.phrase.count > $1.phrase.count }) {
            let phrase = entry.phrase.split(separator: " ").map(String.init)
            guard let range = window(of: phrase, in: folded) else { continue }
            words.removeSubrange(range)
            return (clean(words.joined(separator: " ")), entry.category, entry.tier)
        }
        return (clean(appellation), nil, nil)
    }

    /// The category found anywhere in a text, "… VINHO REGIONAL LISBOA …" → ("Vinho Regional", .regional).
    public static func category(in text: String) -> (category: String, tier: AppellationTier)? {
        let folded = WineText.folded(text)
        if folded.range(of: #" appellation( [a-z0-9]+){1,4} (controlee|protegee) "#, options: .regularExpression) != nil {
            return folded.contains(" controlee ") ? ("AOC", .protected) : ("AOP", .protected)
        }
        return categories.sorted { $0.phrase.count > $1.phrase.count }
            .first { folded.contains(" \($0.phrase) ") }
            .map { ($0.category, $0.tier) }
    }

    /// The appellation a wine keeps when a reading brings another (CELLAR-R17, R30): the one it had, unless it had
    /// none, or the reading names the same place with its category ("Lisboa" → "Vinho Regional Lisboa").
    public static func appellation(_ kept: String?, adding read: String?) -> String? {
        guard let kept else { return read }
        guard let read else { return kept }
        let old = split(kept)
        let new = split(read)
        guard old.category == nil, new.category != nil else { return kept }
        let place = { (name: String?) in WineText.tokens(name ?? "") }
        return place(new.name) == place(old.name) ? read : kept
    }

    /// The words of `phrase`, one token list per word of the label, at consecutive positions.
    private static func window(of phrase: [String], in words: [[String]]) -> Range<Int>? {
        guard !phrase.isEmpty else { return nil }
        for start in words.indices {
            var tokens: [String] = []
            var end = start
            while end < words.count, tokens.count < phrase.count {
                tokens += words[end]
                end += 1
            }
            if tokens == phrase { return start..<end }
        }
        return nil
    }

    private static func clean(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "-–·,.")))
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: Legal terms

    /// Folded phrase → the term as written on the card, longest first.
    static let designations: [(phrase: String, designation: String)] = [
        ("grande reserva", "Grande Reserva"), ("gran reserva", "Gran Reserva"), ("riserva", "Riserva"),
        ("reserva", "Reserva"), ("crianza", "Crianza"), ("reserve", "Reserve")
    ]

    /// The legal terms, as the card writes them, for choosing one by hand (CELLAR-R23).
    public static var designationNames: [String] { designations.map(\.designation) }

    /// The legal term found in a text, as the card writes it: "GRANDE RESERVA" → "Grande Reserva". "Reservado" is
    /// not one.
    public static func designation(in text: String) -> String? {
        let folded = WineText.folded(text)
        return designations.first { folded.contains(" \($0.phrase) ") }?.designation
    }

    /// What the law makes of the term where the wine is from: a Grande Reserva is long ageing and an approval in
    /// Portugal, a word anywhere else.
    public static func strength(of designation: String, country: String?) -> DesignationStrength? {
        guard let term = designations.first(where: { $0.phrase == WineText.tokens(designation).joined(separator: " ") })?
            .designation else { return nil }
        let iberian = country == "Portugal" || country == "Spain"
        switch term {
        case "Grande Reserva", "Gran Reserva": return iberian ? .strong : .weak
        case "Riserva": return country == "Italy" ? .strong : .weak
        case "Reserva", "Crianza": return iberian ? .aged : .weak
        default: return .weak
        }
    }

    // MARK: Medals, competitions and critics

    /// Folded phrase → medal, longest first when matched. "Or" alone is not one: it is a word in French and English.
    static let medals: [(phrase: String, medal: WineAward.Medal)] = [
        ("double gold", .doubleGold), ("grand gold", .doubleGold), ("grande medaille d or", .doubleGold),
        ("best in show", .trophy), ("trophy", .trophy), ("trophee", .trophy),
        ("platinum", .platinum), ("platina", .platinum),
        ("gold", .gold), ("ouro", .gold), ("medaille d or", .gold), ("oro", .gold), ("goldmedaille", .gold),
        ("silver", .silver), ("prata", .silver), ("medaille d argent", .silver), ("plata", .silver),
        ("argento", .silver), ("silbermedaille", .silver),
        ("bronze", .bronze), ("bronce", .bronze), ("bronzo", .bronze), ("medaille de bronze", .bronze),
        ("commended", .commended), ("seal of approval", .commended)
    ]

    public static let sources: [AwardSource] = [
        AwardSource(name: "Decanter World Wine Awards", aliases: ["decanter world wine awards", "decanter wwa", "dwwa"],
                    tier: .major, isCritic: false),
        AwardSource(name: "International Wine Challenge", aliases: ["international wine challenge", "iwc"],
                    tier: .major, isCritic: false),
        AwardSource(name: "International Wine & Spirit Competition",
                    aliases: ["international wine spirit competition", "iwsc"], tier: .major, isCritic: false),
        AwardSource(name: "Concours Mondial de Bruxelles", aliases: ["concours mondial de bruxelles", "concours mondial"],
                    tier: .major, isCritic: false),
        AwardSource(name: "Mundus Vini", aliases: ["mundus vini"], tier: .major, isCritic: false),
        AwardSource(name: "Berliner Wein Trophy", aliases: ["berliner wein trophy"], tier: .major, isCritic: false),
        AwardSource(name: "San Francisco International Wine Competition",
                    aliases: ["san francisco international wine competition"], tier: .major, isCritic: false),
        AwardSource(name: "Concours Général Agricole", aliases: ["concours general agricole"], tier: .major,
                    isCritic: false),
        AwardSource(name: "Challenge International du Vin", aliases: ["challenge international du vin"], tier: .known,
                    isCritic: false),
        AwardSource(name: "Concours International de Lyon", aliases: ["concours international de lyon", "concours de lyon"],
                    tier: .known, isCritic: false),
        AwardSource(name: "Gilbert & Gaillard", aliases: ["gilbert gaillard"], tier: .known, isCritic: false),
        AwardSource(name: "Asia Wine Trophy", aliases: ["asia wine trophy"], tier: .known, isCritic: false),
        AwardSource(name: "AWC Vienna", aliases: ["awc vienna"], tier: .known, isCritic: false),
        AwardSource(name: "Sakura Japan Women's Wine Awards", aliases: ["sakura"], tier: .known, isCritic: false),
        AwardSource(name: "Concurso Vinhos de Portugal", aliases: ["concurso vinhos de portugal"], tier: .known,
                    isCritic: false),
        AwardSource(name: "Decanter", aliases: ["decanter"], tier: .major, isCritic: false),
        AwardSource(name: "Robert Parker", aliases: ["robert parker", "wine advocate", "parker"], tier: .major,
                    isCritic: true),
        AwardSource(name: "Wine Spectator", aliases: ["wine spectator"], tier: .major, isCritic: true),
        AwardSource(name: "James Suckling", aliases: ["james suckling", "suckling"], tier: .major, isCritic: true),
        AwardSource(name: "Wine Enthusiast", aliases: ["wine enthusiast"], tier: .major, isCritic: true),
        AwardSource(name: "Vinous", aliases: ["vinous", "antonio galloni"], tier: .major, isCritic: true),
        AwardSource(name: "Tim Atkin", aliases: ["tim atkin"], tier: .known, isCritic: true),
        AwardSource(name: "Jeb Dunnuck", aliases: ["jeb dunnuck"], tier: .known, isCritic: true),
        AwardSource(name: "Falstaff", aliases: ["falstaff"], tier: .known, isCritic: true),
        AwardSource(name: "Guía Peñín", aliases: ["guia penin", "penin"], tier: .known, isCritic: true)
    ]

    /// The competition or critic named in a text, the longest spelling first: "DECANTER WORLD WINE AWARDS" is the
    /// awards, not the magazine.
    public static func source(in text: String) -> AwardSource? {
        let folded = WineText.folded(text)
        return sources
            .flatMap { source in source.aliases.map { (alias: $0, source: source) } }
            .sorted { $0.alias.count > $1.alias.count }
            .first { folded.contains(" \($0.alias) ") }?
            .source
    }

    public static func medal(in text: String) -> WineAward.Medal? {
        let folded = WineText.folded(text)
        return medals.sorted { $0.phrase.count > $1.phrase.count }.first { folded.contains(" \($0.phrase) ") }?.medal
    }
}
