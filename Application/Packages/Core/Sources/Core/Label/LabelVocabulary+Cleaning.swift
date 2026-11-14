import Foundation

/// The aromas a wine's note may name (CELLAR-R17): a reading's word that is none of them ("Firate", "Pe", "Eaten",
/// a colour alone such as "Red" or "Black") is not an aroma. The list is fixed here, never taken from the wines on
/// the phone: a scanned wine that stored noise would otherwise teach it its noise.
public enum AromaVocabulary {
    /// Every aroma of the UVVA catalog's notes, and common ones it has no wine for yet, folded, as the card writes
    /// them.
    public static let common: [String: String] = Dictionary(uniqueKeysWithValues: [
        "Acacia", "Allspice", "Almond", "Anise", "Apple", "Apricot", "Banana", "Bay leaf", "Black cherry",
        "Black fruit", "Black olive", "Black pepper", "Blackberry", "Blackcurrant", "Blueberry", "Brioche", "Butter",
        "Butterscotch", "Caramel", "Cardamom", "Cassis", "Cedar", "Chamomile", "Cherry", "Chocolate", "Cigar box",
        "Cinnamon", "Citrus", "Clove", "Cocoa", "Coconut", "Coffee", "Cranberry", "Cream", "Currant",
        "Dark chocolate", "Date", "Dill", "Dried fig", "Dried fruit", "Earth", "Elderflower", "Eucalyptus", "Fennel",
        "Fig", "Fir", "Flint", "Floral", "Forest floor", "Game", "Garrigue", "Ginger", "Gooseberry", "Graphite",
        "Grapefruit", "Grass", "Green apple", "Guava", "Hay", "Hazelnut", "Herbs", "Hibiscus", "Honey",
        "Honeysuckle", "Iris", "Jam", "Jasmine", "Kiwi", "Lavender", "Leather", "Lemon", "Licorice", "Lilac", "Lime",
        "Lychee", "Mango", "Marzipan", "Melon", "Menthol", "Mineral", "Mint", "Mocha", "Mushroom", "Nectarine",
        "Nutmeg", "Nuts", "Oak", "Olive", "Orange", "Orange blossom", "Orange peel", "Papaya", "Passion fruit",
        "Peach", "Pear", "Peony", "Pepper", "Petrol", "Pine", "Pineapple", "Plum", "Pomegranate", "Prune", "Quince",
        "Raisin", "Raspberry", "Red cherry", "Red currant", "Red fruit", "Rose", "Rosemary", "Sage", "Saline",
        "Sawdust", "Smoke", "Spice", "Stone fruit", "Strawberry", "Sweet spice", "Tea", "Thyme", "Toast", "Tobacco",
        "Tropical fruit", "Truffle", "Vanilla", "Violet", "Walnut", "White flowers", "White pepper", "Wild berries"
    ].map { (WineText.tokens($0).joined(separator: " "), $0) })

    /// The words a reading uses for an aroma it names otherwise: "Spicy" is Spice, "Cacau" Cocoa.
    static let synonyms: [String: String] = [
        "spicy": "spice", "spices": "spice", "spiced": "spice", "smoky": "smoke", "smoked": "smoke",
        "earthy": "earth", "oaky": "oak", "peppery": "pepper", "herbal": "herbs", "herby": "herbs", "minty": "mint",
        "toasty": "toast", "toasted": "toast", "nutty": "nuts", "flowers": "floral", "flowery": "floral",
        "cacao": "cocoa", "cacau": "cocoa", "chocolat": "chocolate", "chocolate notes": "chocolate",
        "dark fruit": "black fruit", "dark fruits": "black fruit", "black fruits": "black fruit",
        "red fruits": "red fruit", "red berries": "red fruit", "black berries": "blackberry",
        "liquorice": "licorice", "sweet spices": "sweet spice", "fir tree": "fir", "pine needles": "pine",
        "dark chocolate notes": "dark chocolate", "ripe red fruit": "red fruit", "ripe black fruit": "black fruit",
        "ripe dark fruit": "black fruit", "red and black fruit": "red fruit", "black and red fruit": "black fruit"
    ]

    /// "black cherry" → "Black cherry".
    static func written(_ note: String) -> String {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ".")))
        return trimmed.prefix(1).uppercased() + trimmed.dropFirst().lowercased()
    }
}

public extension LabelVocabulary {
    /// The aroma a note names, as the card writes it; nil for a word that is no aroma.
    func aroma(_ note: String) -> String? {
        var key = WineText.tokens(note).joined(separator: " ")
        key = AromaVocabulary.synonyms[key] ?? key
        if let found = aromas[key] { return found }
        // "Cherries", "Plums".
        for ending in ["ies", "es", "s"] where key.hasSuffix(ending) && key.count > ending.count + 2 {
            let singular = String(key.dropLast(ending.count)) + (ending == "ies" ? "y" : "")
            if let found = aromas[AromaVocabulary.synonyms[singular] ?? singular] { return found }
        }
        return nil
    }

    /// The notes that name an aroma, each once, as the card writes them.
    func aromas(in notes: [String]) -> [String] {
        notes.compactMap(aroma).reduce(into: []) { kept, note in
            if !kept.contains(note) { kept.append(note) }
        }
    }

    /// The catalog's producer a reading names, as the catalog writes it: the same words, or a letter or two the
    /// camera got wrong ("CASA SANTOS LEIA" is Casa Santos Lima). Nil when none is that close, or two are.
    func knownProducer(_ producer: String) -> String? {
        let key = WineText.tokens(producer).joined(separator: " ")
        guard !key.isEmpty else { return nil }
        if let found = producers[key] { return found }
        let close = producers.filter { LabelScan.isSameLine($0.key, key) }
        return close.count == 1 ? close.first?.value : nil
    }

    /// What was read, with the notes that are no aroma left out and the producer as the catalog writes it.
    func cleaning(_ facts: LabelFacts) -> LabelFacts {
        var cleaned = facts
        cleaned.notes = aromas(in: facts.notes)
        if let producer = facts.producer, let known = knownProducer(producer) { cleaned.producer = known }
        return cleaned
    }

    /// A wine as a reading leaves it, cleaned the same way: a wine scanned before keeps none of the noise an older
    /// reading stored in it.
    func cleaning(_ wine: Wine) -> Wine {
        var cleaned = wine
        let notes = aromas(in: wine.noteItems)
        cleaned.note = notes.isEmpty ? nil : notes.joined(separator: ", ")
        if let known = knownProducer(wine.producer) { cleaned.producer = known }
        return cleaned
    }
}
