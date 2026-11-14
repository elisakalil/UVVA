import Core
import Foundation
import Match
import SwiftData

/// `CatalogRepository` on the Content store.
public actor CatalogStore: StoreActor, CatalogRepository, WineLookup, LabelCatalogRepository {
    public nonisolated let executor: StoreExecutor
    /// The public catalog, asked when a label is not found on the phone. Nil in the tests and the previews.
    private let cloud: (any CatalogCloudService)?

    public init(modelContainer: ModelContainer, cloud: (any CatalogCloudService)? = nil) {
        executor = StoreExecutor(modelContainer, label: "app.uvva.store.catalog")
        self.cloud = cloud
    }

    /// Where a wine scanned from a label, and not found in the catalog, came from (`WineEntity.source`).
    static let scannedSource = WineEntity.scannedSource

    public func allWines() throws -> [Wine] {
        try modelContext.fetch(FetchDescriptor<WineEntity>()).map(Self.wine)
    }

    /// Also queues what was read as the user's contribution to the public catalog (ARCHITECTURE §4.3): for a
    /// scanned wine, all its readings here added up; for a catalog wine, the catalog's facts with what the label
    /// added, which the robot adds to the catalog once other users read the same.
    public func addScanned(_ wine: Wine) throws {
        let key = wine.id
        var descriptor = FetchDescriptor<WineEntity>(predicate: #Predicate { $0.wineKey == key })
        descriptor.fetchLimit = 1
        if let found = try modelContext.fetch(descriptor).first {
            // A wine scanned before gains what this reading added; a catalog wine is left as it is.
            if found.source == Self.scannedSource {
                Self.accumulate(wine, into: found)
                try PendingContributionEntity.enqueue(Self.wine(found), in: modelContext)
            } else {
                try PendingContributionEntity.enqueue(wine, in: modelContext)
            }
            try modelContext.save()
            return
        }
        let entity = WineEntity(wineKey: wine.id, source: Self.scannedSource)
        entity.name = wine.name
        entity.producer = wine.producer
        entity.vintage = wine.vintage
        entity.origin = wine.origin
        entity.region = wine.region
        entity.country = wine.country
        entity.grapes = wine.grapes
        entity.type = wine.type
        entity.alcohol = wine.alcohol
        entity.classification = wine.classification
        entity.note = wine.note ?? ""
        entity.pairings = wine.pairings
        entity.designation = wine.designation
        entity.awards = wine.awards.map(\.text)
        entity.appellationInsight = wine.appellationInsight
        entity.hasNotableAppellation = wine.hasNotableAppellation
        // An unknown serving temperature stays min > max, which reads back as none.
        entity.servingMin = wine.serving?.lowerBound ?? 1
        entity.servingMax = wine.serving?.upperBound ?? 0
        entity.floral = wine.profile[.floral]
        entity.body = wine.profile[.body]
        entity.tannin = wine.profile[.tannin]
        entity.spice = wine.profile[.spice]
        entity.oak = wine.profile[.oak]
        entity.sweetness = wine.profile[.sweetness]
        entity.acidity = wine.profile[.acidity]
        entity.fruit = wine.profile[.fruit]
        modelContext.insert(entity)
        try PendingContributionEntity.enqueue(wine, in: modelContext)
        try modelContext.save()
    }

    public func forgetScanned(_ wineKey: String) async throws {
        let wine = FetchDescriptor<WineEntity>(predicate: #Predicate { $0.wineKey == wineKey })
        for entity in try modelContext.fetch(wine) where entity.source == Self.scannedSource {
            modelContext.delete(entity)
        }
        let pending = FetchDescriptor<PendingContributionEntity>(predicate: #Predicate { $0.wineKey == wineKey })
        for entity in try modelContext.fetch(pending) { modelContext.delete(entity) }
        try modelContext.save()
    }

    /// The wines of the public catalog that share words with a label, kept on the phone so the note and the map find
    /// them like any other (ARCHITECTURE §4.1). Empty without a network or a public catalog.
    public func publicWines(sharing tokens: Set<String>) async throws -> [Wine] {
        guard let cloud, !tokens.isEmpty else { return [] }
        let found = try await cloud.wines(sharing: tokens)
        guard !found.isEmpty else { return [] }
        let keys = found.map(\.id)
        let existing = Dictionary(try modelContext.fetch(FetchDescriptor<WineEntity>(
            predicate: #Predicate { keys.contains($0.wineKey) })).map { ($0.wineKey, $0) }) { first, _ in first }
        for data in found {
            WineEntity.upsert(data, existing: existing[data.id], in: modelContext)
        }
        try modelContext.save()
        return found.map(\.wine)
    }

    /// CELLAR-R17, R30: every reading of a scanned wine leaves it richer. Its grapes, notes, pairings and awards gain
    /// the new ones; the serving temperature, alcohol and legal term are kept once known, and the appellation gains
    /// its category when a reading brings it; its name, producer and map stay as first read.
    private static func accumulate(_ wine: Wine, into entity: WineEntity) {
        let stored = Self.wine(entity)
        entity.grapes = stored.grapes.adding(wine.grapes)
        entity.pairings = stored.pairings.adding(wine.pairings)
        entity.note = stored.addingNotes(wine.noteItems).note ?? ""
        if stored.serving == nil, let serving = wine.serving {
            entity.servingMin = serving.lowerBound
            entity.servingMax = serving.upperBound
        }
        if entity.alcohol == nil { entity.alcohol = wine.alcohol }
        entity.awards = stored.awards.adding(wine.awards).map(\.text)
        if entity.designation == nil { entity.designation = wine.designation }
        if let kept = CertificationKeywords.appellation(stored.appellation, adding: wine.appellation),
           kept != stored.appellation {
            entity.classification = stored.settingAppellation(kept).classification
        }
        if entity.appellationInsight == nil {
            entity.appellationInsight = wine.appellationInsight
            entity.hasNotableAppellation = entity.hasNotableAppellation || wine.hasNotableAppellation
        }
    }

    public func wines(keys: Set<String>) throws -> [String: Wine] {
        guard !keys.isEmpty else { return [:] }
        let wanted = Array(keys)
        let descriptor = FetchDescriptor<WineEntity>(predicate: #Predicate { wanted.contains($0.wineKey) })
        return Dictionary(try modelContext.fetch(descriptor).map { ($0.wineKey, Self.wine($0)) }) { first, _ in first }
    }

    /// Reads the eight axes of every wine, ranks them by similarity and builds full wines only for the best. Wines
    /// equally close go by their key, so the top of the list is the same wine on every read (HOME-R07).
    public func winesClosest(to map: PalateMap, limit: Int) throws -> [Wine] {
        var descriptor = FetchDescriptor<WineEntity>()
        descriptor.propertiesToFetch = [\.wineKey, \.floral, \.body, \.tannin, \.spice, \.oak, \.sweetness, \.acidity, \.fruit]
        let scored: [(entity: WineEntity, score: Double)] = try modelContext.fetch(descriptor)
            .map { (entity: $0, score: Similarity.between($0.palateMap, map)) }
        let ranked = scored
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.entity.wineKey < rhs.entity.wineKey
            }
            .prefix(limit)
        return ranked.map { Self.wine($0.entity) }
    }

    public func recipes() throws -> [Recipe] {
        try modelContext.fetch(FetchDescriptor<RecipeEntity>()).map { entity in
            Recipe(id: entity.id, title: entity.title, why: entity.why, course: entity.course,
                   wineTypes: entity.wineTypes, profile: entity.palateMap, ingredients: entity.ingredients,
                   steps: entity.steps, servings: entity.servings, minutes: entity.prepMinutes + entity.cookMinutes)
        }
    }

    public func glossary() throws -> [GlossaryTerm] {
        try modelContext.fetch(FetchDescriptor<GlossaryTermEntity>(sortBy: [SortDescriptor(\.term)])).map {
            GlossaryTerm(term: $0.term, pronunciation: $0.pronunciation ?? "", definition: $0.definition, aka: $0.aka, lesson: $0.lesson)
        }
    }

    public func firstPathModule() throws -> CourseSummary? {
        var descriptor = FetchDescriptor<ModuleEntity>(predicate: #Predicate { $0.kind == "path" },
                                                       sortBy: [SortDescriptor(\.order)])
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first.map {
            CourseSummary(id: $0.id, title: $0.title, lessonCount: $0.lessonCount, minutes: $0.estimatedMinutes)
        }
    }

    static func wine(_ entity: WineEntity) -> Wine {
        Wine(id: entity.wineKey, name: entity.name, producer: entity.producer, vintage: entity.vintage,
             type: entity.type, origin: entity.origin, region: entity.region, country: entity.country,
             grapes: entity.grapes, alcohol: entity.alcohol,
             classification: entity.classification, profile: entity.palateMap,
             note: entity.note.isEmpty ? nil : entity.note,
             serving: entity.servingMin <= entity.servingMax ? entity.servingMin...entity.servingMax : nil,
             originInsight: entity.originInsight, appellationInsight: entity.appellationInsight,
             hasNotableAppellation: entity.hasNotableAppellation, howToServe: entity.howToServe, pairings: entity.pairings,
             designation: entity.designation, awards: entity.awards.compactMap(WineAward.init(text:)))
    }
}
