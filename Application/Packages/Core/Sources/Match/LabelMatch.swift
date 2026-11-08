import Core
import Foundation

/// Finds the wine of a label in the catalog on the phone (CELLAR-R17): by the words of its name and producer,
/// helped by the vintage and the type.
public enum LabelMatch {
    /// Under this a wine is not offered at all.
    static let minimumScore = 0.4
    /// From this up, with name and producer each half found, the match is taken as it is.
    static let confidentScore = 0.75

    public static func best(for facts: LabelFacts, in index: LabelCatalogIndex) -> LabelMatchResult? {
        let label = labelTokens(facts)
        let scored = index.candidates(sharing: label)
            .map { (entry: $0, score: score($0, label: label, facts: facts)) }
            .filter { $0.score.total >= minimumScore }
        guard let best = scored.min(by: { lhs, rhs in
            if lhs.score.total != rhs.score.total { return lhs.score.total > rhs.score.total }
            return lhs.entry.wine.id < rhs.entry.wine.id
        }) else { return nil }
        let confident = best.score.total >= confidentScore && best.score.name >= 0.5 && best.score.producer >= 0.5
            && best.score.found >= 2
        return LabelMatchResult(wine: wine(best.entry.wine, as: facts, confident: confident),
                                score: min(1, best.score.total), isConfident: confident)
    }

    /// Every word of the lines that could be the name or producer, and of the appellation and region, since a wine
    /// can be named after them ("Douro").
    private static func labelTokens(_ facts: LabelFacts) -> Set<String> {
        let texts = facts.titleLines + [facts.name, facts.producer, facts.appellation, facts.region].compactMap { $0 }
        return texts.reduce(into: Set<String>()) { $0.formUnion(WineText.significantTokens($1)) }
    }

    private static func score(_ entry: LabelCatalogEntry, label: Set<String>,
                              facts: LabelFacts) -> (total: Double, name: Double, producer: Double, found: Int) {
        let foundName = entry.name.intersection(label).count
        let foundProducer = entry.producer.subtracting(entry.name).intersection(label).count
        let name = entry.name.isEmpty ? 0 : Double(foundName) / Double(entry.name.count)
        let producer = entry.producer.isEmpty ? name : Double(entry.producer.intersection(label).count) / Double(entry.producer.count)
        var total = 0.55 * name + 0.45 * producer
        if let vintage = facts.vintage, let wineVintage = entry.wine.vintage {
            total += vintage == wineVintage ? 0.1 : -0.05
        }
        if let type = facts.type, type != entry.wine.type { total -= 0.25 }
        return (total, name, producer, foundName + foundProducer)
    }

    /// The catalog wine as the label shows it: another vintage makes another wine (CELLAR-R13a), with the same
    /// profile and the label's alcohol.
    private static func wine(_ wine: Wine, as facts: LabelFacts, confident: Bool) -> Wine {
        guard confident, let vintage = facts.vintage, vintage != wine.vintage else { return wine }
        var other = wine
        other.vintage = vintage
        other.id = WineKey.make(producer: wine.producer, name: wine.name, vintage: vintage)
        other.alcohol = facts.alcohol ?? wine.alcohol
        return other
    }
}
