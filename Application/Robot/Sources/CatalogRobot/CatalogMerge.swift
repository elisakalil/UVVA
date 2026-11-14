import Core
import Foundation
import Match

/// What the users who read one wine agree on.
public struct CommunityEntry: Codable, Equatable, Sendable {
    public var wineKey: String
    /// How many users read it, the last time its contributions were counted.
    public var contributors: Int
    /// Once enough users read it, it stays in the catalog, even if some of them later delete their account.
    public var promoted: Bool
    /// The facts of the wine as most of its readers saw them; lists keep only what `quorum` readers saw.
    public var facts: CatalogWineData
    /// The lists as every reader saw them, for a new wine whose readers agree on none of an item.
    public var allGrapes: [String]

    public init(wineKey: String, contributors: Int, promoted: Bool, facts: CatalogWineData, allGrapes: [String]) {
        self.wineKey = wineKey
        self.contributors = contributors
        self.promoted = promoted
        self.facts = facts
        self.allGrapes = allGrapes
    }
}

/// How the robot turns the users' readings into the catalog (ARCHITECTURE §4.3), without anyone to approve them:
///
/// - A wine the catalog does not have enters it once `quorum` different users read it.
/// - A catalog wine gains a grape, a pairing, an aroma or an award once `quorum` users read it on the label, and a
///   fact it lacks (alcohol, serving temperature, legal term) once `quorum` users agree on it. What the seed says is
///   never replaced.
public enum CatalogMerge {
    public static let quorum = 2

    /// The entry of one wine from all its contributions (only valid ones); nil without any.
    public static func entry(_ contributions: [Contribution], previous: CommunityEntry?) -> CommunityEntry? {
        // One reading per user: the latest.
        let latest = Dictionary(grouping: contributions, by: \.contributor)
            .compactMap { $0.value.max { $0.modified < $1.modified } }
            .sorted { $0.created < $1.created }
        guard let first = latest.first else { return previous }
        let wines = latest.map(\.wine)
        let count = wines.count

        var facts = first.wine
        facts.name = majority(wines.map(\.name)) ?? first.wine.name
        facts.producer = majority(wines.map(\.producer)) ?? first.wine.producer
        facts.vintage = majority(wines.map(\.vintage)) ?? first.wine.vintage
        facts.type = majority(wines.map(\.type).filter { !$0.isEmpty }) ?? ""
        facts.origin = majority(wines.map(\.origin).filter { !$0.isEmpty }) ?? ""
        facts.region = majority(wines.compactMap(\.region))
        facts.country = majority(wines.compactMap(\.country))
        facts.classification = majority(wines.map(\.classification).filter { !$0.isEmpty }) ?? ""
        facts.alcohol = majority(wines.compactMap(\.alcohol), atLeast: quorum)
        facts.servingTemperature = majority(wines.compactMap(\.servingTemperature), atLeast: quorum)
        facts.designation = majority(wines.compactMap(\.designation), atLeast: quorum)
        facts.grapes = agreed(wines.map(\.grapes))
        facts.pairings = agreed(wines.map(\.pairings))
        facts.awards = agreed(wines.map { $0.awards ?? [] }).nilIfEmpty
        let notes = agreed(wines.map { $0.wine.noteItems })
        facts.note = notes.isEmpty ? nil : notes.joined(separator: ", ")
        facts.findIt = nil
        facts.howToServe = nil
        facts.originInsight = nil
        return CommunityEntry(wineKey: first.wineKey, contributors: count,
                              promoted: (previous?.promoted ?? false) || count >= quorum, facts: facts,
                              allGrapes: wines.map(\.grapes).reduce([]) { $0.adding($1) })
    }

    /// The catalog: the seed, each wine with what its readers agree on, and the wines enough users made known.
    public static func catalog(seed: [CatalogWineData], entries: [String: CommunityEntry]) -> [CatalogWineData] {
        var wines = Dictionary(seed.map { ($0.id, $0) }) { first, _ in first }
        for (key, entry) in entries where wines[key] != nil {
            wines[key] = enriched(wines[key]!, with: entry)
        }
        let reference = seed.map(\.wine)
        let vocabulary = LabelVocabulary(wines: reference)
        for (key, entry) in entries where wines[key] == nil && entry.promoted {
            if let wine = newWine(entry, reference: reference, vocabulary: vocabulary) { wines[key] = wine }
        }
        return wines.values.sorted { $0.id < $1.id }
    }

    static func enriched(_ seed: CatalogWineData, with entry: CommunityEntry) -> CatalogWineData {
        guard entry.contributors >= quorum else { return seed }
        let facts = entry.facts.wine
        var wine = seed.wine
        wine.grapes = wine.grapes.adding(facts.grapes)
        wine.pairings = wine.pairings.adding(facts.pairings)
        wine = wine.addingNotes(facts.noteItems)
        wine.awards = wine.awards.adding(facts.awards)
        wine.alcohol = wine.alcohol ?? facts.alcohol
        wine.serving = wine.serving ?? facts.serving
        wine.designation = wine.designation ?? facts.designation
        guard wine != seed.wine else { return seed }
        var result = CatalogWineData(wine, findIt: seed.findIt)
        result.hasNotableAppellation = seed.hasNotableAppellation
        return result
    }

    /// A wine the catalog did not have, with its map estimated from the wines most like it, as the app does for a
    /// label it does not find. Nil while too little is known to place it.
    static func newWine(_ entry: CommunityEntry, reference: [Wine], vocabulary: LabelVocabulary) -> CatalogWineData? {
        var facts = entry.facts
        if facts.grapes.isEmpty { facts.grapes = entry.allGrapes }
        guard CatalogSchema.wineTypes.contains(facts.type), !facts.name.isEmpty,
              let map = ProfileEstimate.estimate(grapes: facts.grapes, type: facts.type, region: facts.region,
                                                 in: reference) else { return nil }
        var wine = facts.wine
        wine.profile = map
        wine = vocabulary.describingAppellation(of: wine)
        return CatalogWineData(wine)
    }

    /// The value most of the readers saw, the earliest reading winning a tie; nil when fewer than `atLeast` saw it.
    static func majority<T: Hashable>(_ values: [T], atLeast: Int = 1) -> T? {
        var counts: [T: Int] = [:]
        for value in values { counts[value, default: 0] += 1 }
        guard let best = counts.values.max(), best >= atLeast else { return nil }
        return values.first { counts[$0] == best }
    }

    /// The items `quorum` readers saw (whatever the case), in the order first read.
    static func agreed(_ lists: [[String]]) -> [String] {
        var counts: [String: Int] = [:]
        for list in lists {
            for key in Set(list.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }) where !key.isEmpty {
                counts[key, default: 0] += 1
            }
        }
        return lists.reduce([]) { $0.adding($1) }.filter { (counts[$0.lowercased()] ?? 0) >= quorum }
    }
}

extension Array {
    var nilIfEmpty: Self? { isEmpty ? nil : self }
}
