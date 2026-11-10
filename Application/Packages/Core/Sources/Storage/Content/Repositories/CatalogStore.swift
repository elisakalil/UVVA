import Core
import Foundation
import Match
import SwiftData

/// `CatalogRepository` on the Content store.
@ModelActor
public actor CatalogStore: CatalogRepository, WineLookup, LabelCatalogRepository {
    /// Where a wine scanned from a label, and not found in the catalog, came from (`WineEntity.source`).
    static let scannedSource = "scanned"

    public func allWines() throws -> [Wine] {
        try modelContext.fetch(FetchDescriptor<WineEntity>()).map(Self.wine)
    }

    public func addScanned(_ wine: Wine) throws {
        guard try wines(keys: [wine.id]).isEmpty else { return }
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
        try modelContext.save()
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
             hasNotableAppellation: entity.hasNotableAppellation, howToServe: entity.howToServe, pairings: entity.pairings)
    }
}
