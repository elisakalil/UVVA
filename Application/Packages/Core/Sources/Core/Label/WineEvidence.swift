import Foundation

/// Whether the photos show a wine's label at all (CELLAR-R21a): a bag of sugar has a name in big type too, and
/// without this it would be read as a wine the catalog does not know, with the catalog's average map.
///
/// Judged only on what was read on the photos and what the parser made of it, never on the model's reading: the
/// model fills in a wine whatever it is shown.
///
/// - A strong sign is enough: a grape, a word for wine ("vinho", "vin", "espumante"…), or the alcohol written as
///   wine writes it ("13,5% vol").
/// - Otherwise it takes three weak ones, each of which food labels also carry: an appellation or wine region, an
///   appellation category (DOC, IGP), a colour word ("branco"), a wine producer's word ("Quinta", "Château"),
///   sulfites, a legal ageing term, a medal.
/// - Beer, spirits, cider, vinegar and juice say "% vol" and "tinto" too: with one of their words, only a grape or
///   a word for wine makes it a wine.
public enum WineEvidence {
    static let weakSignsNeeded = 3
    /// The strength of still, sparkling and fortified wines; beer starts lower, spirits higher.
    public static let wineStrength = 4.5...23.0

    public static func isWine(_ text: LabelText, facts: LabelFacts) -> Bool {
        let folded = WineText.folded(text.lines.map(\.text).joined(separator: " "))
        let says = { (words: Set<String>) in words.contains { folded.contains(" \($0) ") } }
        let namesWine = says(wineWords)
        if says(otherProducts), !namesWine, facts.grapes.isEmpty { return false }
        let alcohol = LabelParser.labeledAlcohol(in: text.lines, within: wineStrength) != nil
        if namesWine || !facts.grapes.isEmpty || alcohol { return true }
        let weak = [
            facts.appellation != nil || facts.region != nil,
            text.lines.contains { CertificationKeywords.category(in: $0.text) != nil },
            facts.type != nil,
            says(producerWords),
            says(sulfites),
            facts.designation != nil,
            !facts.awards.isEmpty
        ]
        return weak.filter { $0 }.count >= weakSignsNeeded
    }

    /// Folded, matched as whole words.
    static let wineWords: Set<String> = [
        "vinho", "vinhos", "wine", "wines", "vin", "vins", "vino", "vini", "vinos", "wein", "weine", "weisswein",
        "rotwein", "rosewein", "schaumwein", "espumante", "espumoso", "champagne", "prosecco", "cremant", "sekt",
        "spumante", "franciacorta", "vinho do porto", "port wine", "vin doux naturel", "vinho generoso"
    ]

    /// Drinks and foods whose labels look like a wine's.
    static let otherProducts: Set<String> = [
        "cerveja", "beer", "biere", "birra", "cerveza", "bier", "pilsner", "pils", "lager", "stout", "malte", "malt",
        "lupulo", "hops", "hopfen", "vodka", "gin", "whisky", "whiskey", "rum", "rhum", "tequila", "mezcal",
        "cachaca", "brandy", "cognac", "grappa", "licor", "liqueur", "liquore", "cidra", "cider", "cidre", "sidra",
        "vinagre", "vinegar", "vinaigre", "aceto", "essig", "balsamico", "sumo", "suco", "juice", "succo", "zumo",
        "saft", "nectar", "refrigerante", "soda"
    ]

    /// The producer's words only a wine label uses ("Casa", "Monte" or "Family" name anything).
    static let producerWords: Set<String> = [
        "quinta", "chateau", "domaine", "bodega", "bodegas", "herdade", "tenuta", "weingut", "cantina", "cantine",
        "winery", "vineyard", "vineyards", "adega", "clos", "fattoria", "azienda agricola", "vinicola", "vitivinicola"
    ]

    static let sulfites: Set<String> = [
        "sulfitos", "sulfites", "sulphites", "solfiti", "sulfiti", "sulfite", "sulfito", "sulfiet", "sulfiete"
    ]
}
