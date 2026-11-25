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
    /// How many readers gave the region and the appellation of `facts`: one reader's word the catalog does not
    /// know waits for a second (CELLAR-R18a). Nil in entries counted before they were kept.
    public var regionReaders: Int?
    public var appellationReaders: Int?

    public init(wineKey: String, contributors: Int, promoted: Bool, facts: CatalogWineData, allGrapes: [String],
                regionReaders: Int? = nil, appellationReaders: Int? = nil) {
        self.wineKey = wineKey
        self.contributors = contributors
        self.promoted = promoted
        self.facts = facts
        self.allGrapes = allGrapes
        self.regionReaders = regionReaders
        self.appellationReaders = appellationReaders
    }
}

/// How the robot turns the users' readings into the catalog (ARCHITECTURE §4.3), without anyone to approve them:
///
/// - A wine the catalog does not have enters it once `quorum` different users read it.
/// - A catalog wine gains a grape, a pairing, an aroma, an award or a wood once `quorum` users read it on the label,
///   and a fact it lacks (alcohol, serving temperature, legal term, time in wood) once `quorum` users agree on it.
///   What the seed says is never replaced.
/// - A new wine needs a map drawn from what its readers agree on (CELLAR-R23a): the type and a grape, region, note
///   or time in wood the catalog knows. Until then it waits.
/// - A grape, region or appellation the catalog does not know, typed by one person (CELLAR-R18a), enters a new wine
///   only once `quorum` of its readers give it; the lists need that already.
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
        facts.oakAging = majority(wines.compactMap(\.oakAging), atLeast: quorum)
        facts.oakWoods = agreed(wines.map { $0.oakWoods ?? [] }).nilIfEmpty
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
                              allGrapes: wines.map(\.grapes).reduce([]) { $0.adding($1) },
                              regionReaders: readers(of: facts.region, in: wines.map(\.region)),
                              appellationReaders: readers(of: facts.wine.appellation, in: wines.map(\.wine.appellation)))
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
        wine.oakAging = wine.oakAging ?? facts.oakAging
        wine.oakWoods = wine.oakWoods.adding(facts.oakWoods)
        guard wine != seed.wine else { return seed }
        var result = CatalogWineData(wine, findIt: seed.findIt)
        result.hasNotableAppellation = seed.hasNotableAppellation
        return result
    }

    /// A wine the catalog did not have, with its map estimated from the wines most like it, as the app does for a
    /// label it does not find. Nil while too little is known to place it.
    static func newWine(_ entry: CommunityEntry, reference: [Wine], vocabulary: LabelVocabulary) -> CatalogWineData? {
        let known = KnownNames(reference)
        var facts = entry.facts
        // One reader's grapes, region or appellation, when the catalog does not know them, wait for a second.
        if facts.grapes.isEmpty { facts.grapes = entry.allGrapes.filter(known.grapes.knows) }
        if let region = facts.region, (entry.regionReaders ?? 0) < quorum, !known.regions.knows(region) {
            facts.region = nil
        }
        var read = facts.wine
        if let appellation = read.appellation, (entry.appellationReaders ?? 0) < quorum,
           !known.appellations.knows(appellation) {
            read.classification = read.classification.components(separatedBy: " · ").dropFirst()
                .joined(separator: " · ")
        }
        guard CatalogSchema.wineTypes.contains(facts.type), !facts.name.isEmpty,
              let map = ProfileEstimate.estimate(read.readFacts, in: reference) else { return nil }
        var wine = read
        wine.profile = map
        wine = vocabulary.describingAppellation(of: wine)
        return CatalogWineData(wine)
    }

    /// How many readers saw `value`, whatever the case and the accents.
    static func readers(of value: String?, in values: [String?]) -> Int {
        guard let value else { return 0 }
        let key = WineText.tokens(value).joined(separator: " ")
        return values.filter { $0.map { WineText.tokens($0).joined(separator: " ") } == key }.count
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

/// The grapes, regions and appellations the catalog has, folded, to tell one person's new word from a known one.
struct KnownNames {
    struct Names {
        var keys: Set<String>

        init(_ values: some Sequence<String>) {
            keys = Set(values.map(Self.key).filter { !$0.isEmpty })
        }

        func knows(_ value: String) -> Bool { keys.contains(Self.key(value)) }

        /// "Douro DOC" and "douro" are one appellation.
        static func key(_ value: String) -> String {
            WineText.tokens(CertificationKeywords.split(value).name ?? value).joined(separator: " ")
        }
    }

    var grapes: Names
    var regions: Names
    var appellations: Names

    init(_ wines: [Wine]) {
        grapes = Names(wines.flatMap(\.grapes))
        regions = Names(wines.compactMap(\.region))
        appellations = Names(wines.compactMap(\.appellation))
    }
}
