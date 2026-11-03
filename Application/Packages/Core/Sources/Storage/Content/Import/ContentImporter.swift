import Foundation
import SwiftData

@ModelActor
public actor ContentImporter {
    static let batchSize = 500
    
    public func importIfNeeded(
        from source: ContentSource,
        currentVersion: String?,
        protectedWineKeys: Set<String> = [],
        onStage: @Sendable (ContentImportStage) -> Void = { _ in }
    ) throws -> String? {
        let manifest = try decode(ContentManifest.self, at: source.manifest)
        guard manifest.version != currentVersion else { return nil }

        onStage(.quizAndGlossary)
        try importQuestionsIfNeeded(
            from: source,
            currentVersion: currentVersion
        )

        return try importCatalogIfNeeded(
            from: source,
            currentVersion: currentVersion,
            protectedWineKeys: protectedWineKeys,
            onStage: onStage
        )
    }

    public func importQuestionsIfNeeded(
        from source: ContentSource,
        currentVersion: String?
    ) throws {
        try Task.checkCancellation()

        let manifest = try decode(ContentManifest.self, at: source.manifest)
        guard manifest.version != currentVersion else { return }

        try replaceQuiz(
            try decode(PackedQuizFile.self, at: source.quiz).questions
        )

        try Task.checkCancellation()

        try replaceGlossary(
            try decode(PackedGlossaryFile.self, at: source.glossary).terms
        )
    }

    public func importCatalogIfNeeded(
        from source: ContentSource,
        currentVersion: String?,
        protectedWineKeys: Set<String> = [],
        onStage: @Sendable (ContentImportStage) -> Void = { _ in }
    ) throws -> String? {
        try Task.checkCancellation()

        let manifest = try decode(ContentManifest.self, at: source.manifest)
        guard manifest.version != currentVersion else { return nil }

        onStage(.recipes)
        try replaceRecipes(
            try decode(PackedRecipesFile.self, at: source.recipes).recipes
        )
        try Task.checkCancellation()

        onStage(.learn)
        try replaceLearn(
            try decode(PackedLearnFile.self, at: source.learn).modules
        )
        try Task.checkCancellation()

        onStage(.wines)
        try upsertWines(
            try decode(PackedWinesFile.self, at: source.wines).wines,
            protecting: protectedWineKeys
        )
        try Task.checkCancellation()

        return manifest.version
    }

    private func decode<T: Decodable>(_ type: T.Type, at url: URL) throws -> T {
        try JSONDecoder().decode(type, from: Data(contentsOf: url))
    }

    private func replaceQuiz(_ questions: [PackedQuizQuestion]) throws {
        try modelContext.delete(model: QuizQuestionEntity.self)
        for packed in questions {
            let entity = QuizQuestionEntity(axis: packed.axis, version: packed.version)
            entity.prompt = packed.prompt
            entity.answers = packed.answers
            modelContext.insert(entity)
        }
        try modelContext.save()
    }

    private func replaceGlossary(_ terms: [PackedGlossaryTerm]) throws {
        try modelContext.delete(model: GlossaryTermEntity.self)
        for packed in terms {
            let entity = GlossaryTermEntity(id: packed.id)
            entity.term = packed.term
            entity.definition = packed.definition
            entity.pronunciation = packed.pronunciation
            entity.aka = packed.aka
            entity.lesson = packed.lesson
            modelContext.insert(entity)
        }
        try modelContext.save()
    }

    private func replaceRecipes(_ recipes: [PackedRecipe]) throws {
        try modelContext.delete(model: RecipeEntity.self)
        let encoder = JSONEncoder()
        for packed in recipes {
            let entity = RecipeEntity(id: packed.id)
            entity.title = packed.title
            entity.why = packed.why
            entity.course = packed.course
            entity.mainIngredient = packed.mainIngredient
            entity.cuisine = packed.cuisine
            entity.season = packed.season
            entity.diet = packed.diet
            entity.allergens = packed.allergens
            entity.wineTypes = packed.wineTypes
            entity.floral = packed.map.floral
            entity.body = packed.map.body
            entity.tannin = packed.map.tannin
            entity.spice = packed.map.spice
            entity.oak = packed.map.oak
            entity.sweetness = packed.map.sweetness
            entity.acidity = packed.map.acidity
            entity.fruit = packed.map.fruit
            entity.servings = packed.servings
            entity.prepMinutes = packed.prepMinutes
            entity.cookMinutes = packed.cookMinutes
            entity.difficulty = packed.difficulty
            entity.steps = packed.steps
            entity.twistData = try encoder.encode(packed.twist)
            entity.flavorData = try encoder.encode(packed.flavor)
            entity.ingredientsData = try encoder.encode(packed.ingredients)
            modelContext.insert(entity)
        }
        try modelContext.save()
    }

    private func replaceLearn(_ modules: [PackedModule]) throws {
        // One by one, so the cascade removes the lessons: a batch delete fails on the module ↔ lesson relationship.
        for module in try modelContext.fetch(FetchDescriptor<ModuleEntity>()) {
            modelContext.delete(module)
        }
        try modelContext.save()
        let encoder = JSONEncoder()
        for packed in modules {
            let module = ModuleEntity(id: packed.id)
            module.kind = packed.kind
            module.order = packed.order
            module.title = packed.title
            module.about = packed.description
            module.complexity = packed.complexity
            module.lessonCount = packed.lessonCount
            module.xp = packed.xp
            module.estimatedMinutes = packed.estimatedMinutes
            module.level = packed.level
            module.color = packed.color
            module.origin = packed.origin
            module.aliases = packed.aliases ?? []
            module.countries = packed.countries ?? []
            module.country = packed.country
            module.countryCode = packed.countryCode
            module.grapes = packed.grapes ?? []
            module.points = packed.points
            modelContext.insert(module)
            for packedLesson in packed.lessons {
                let lesson = LessonEntity(id: packedLesson.id)
                lesson.moduleId = packedLesson.moduleId
                lesson.order = packedLesson.order
                lesson.title = packedLesson.title
                lesson.subtitle = packedLesson.subtitle
                lesson.xp = packedLesson.xp
                lesson.estimatedMinutes = packedLesson.estimatedMinutes
                lesson.isReview = packedLesson.isReview
                lesson.objectives = packedLesson.objectives
                lesson.stepsData = try encoder.encode(packedLesson.steps)
                lesson.module = module
                modelContext.insert(lesson)
            }
        }
        try modelContext.save()
    }

    private func upsertWines(_ wines: [PackedWine], protecting protected: Set<String>) throws {
        let bundleSource = "bundle"
        var existing: [String: WineEntity] = [:]
        if try modelContext.fetchCount(FetchDescriptor<WineEntity>()) > 0 {
            for wine in try modelContext.fetch(FetchDescriptor<WineEntity>()) {
                existing[wine.wineKey] = wine
            }
        }

        let incoming = Set(wines.map(\.id))
        for wine in existing.values
        where wine.source == bundleSource && !incoming.contains(wine.wineKey) && !protected.contains(wine.wineKey) {
            modelContext.delete(wine)
        }

        for (index, packed) in wines.enumerated() {
            try Task.checkCancellation()
            
            let entity: WineEntity
            if let found = existing[packed.id] {
                entity = found
            } else {
                entity = WineEntity(wineKey: packed.id, source: bundleSource)
                modelContext.insert(entity)
            }
            entity.name = packed.name
            entity.producer = packed.producer
            entity.vintage = packed.vintage
            entity.origin = packed.origin
            entity.region = packed.region
            entity.country = packed.country
            entity.grapes = packed.grapes
            entity.type = packed.type
            entity.alcohol = packed.alcohol
            entity.servingMin = packed.servingTemperature.min
            entity.servingMax = packed.servingTemperature.max
            entity.pairings = packed.pairings
            entity.classification = packed.classification
            entity.findIt = packed.findIt
            entity.note = packed.note ?? ""
            entity.originInsight = packed.originInsight
            entity.appellationInsight = packed.appellationInsight
            entity.hasNotableAppellation = packed.hasNotableAppellation ?? false
            entity.howToServe = packed.howToServe
            entity.floral = packed.map.floral
            entity.body = packed.map.body
            entity.tannin = packed.map.tannin
            entity.spice = packed.map.spice
            entity.oak = packed.map.oak
            entity.sweetness = packed.map.sweetness
            entity.acidity = packed.map.acidity
            entity.fruit = packed.map.fruit
            if (index + 1) % Self.batchSize == 0 { try modelContext.save() }
        }
        try modelContext.save()
    }
}
