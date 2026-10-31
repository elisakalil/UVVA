import Core
import Foundation
import SwiftData
import Testing
@testable import Storage

struct ContentImporterTests {
    let container: ModelContainer
    let importer: ContentImporter

    init() throws {
        container = try ContentStore.makeContainer(url: nil)
        importer = ContentImporter(modelContainer: container)
    }

    private func source(_ fixture: ContentFixture) throws -> ContentSource {
        ContentSource(directory: try fixture.write())
    }

    private func count<T: PersistentModel>(_ type: T.Type) throws -> Int {
        try ModelContext(container).fetchCount(FetchDescriptor<T>())
    }

    private func wines() throws -> [String: WineEntity] {
        let all = try ModelContext(container).fetch(FetchDescriptor<WineEntity>())
        return Dictionary(uniqueKeysWithValues: all.map { ($0.wineKey, $0) })
    }

    // MARK: Primeira abertura

    @Test func firstLaunch_importsEveryKind_andReturnsTheVersion() async throws {
        let version = try await importer.importIfNeeded(from: source(ContentFixture()), currentVersion: nil)
        #expect(version == "v1")
        #expect(try count(WineEntity.self) == 2)
        #expect(try count(RecipeEntity.self) == 2)
        #expect(try count(ModuleEntity.self) == 1)
        #expect(try count(LessonEntity.self) == 2)
        #expect(try count(GlossaryTermEntity.self) == 1)
        #expect(try count(QuizQuestionEntity.self) == 24)
    }

    @Test func wine_keepsItsFields_andHasNoVintageWhenTheBundleHasNone() async throws {
        _ = try await importer.importIfNeeded(from: source(ContentFixture()), currentVersion: nil)
        let wines = try wines()
        #expect(wines["a-wine-2020"]?.vintage == 2020)
        #expect(wines["b-wine"]?.vintage == nil)
        #expect(wines["a-wine-2020"]?.servingMax == 16)
        #expect(wines["a-wine-2020"]?.palateMap[.acidity] == 5)
        #expect(wines["a-wine-2020"]?.source == "bundle")
    }

    @Test func recipe_decodesTwistFlavorAndIngredients() async throws {
        _ = try await importer.importIfNeeded(from: source(ContentFixture()), currentVersion: nil)
        let recipe = try #require(try ModelContext(container).fetch(FetchDescriptor<RecipeEntity>()).first)
        #expect(recipe.twist == RecipeTwist(ingredient: "pepper", axis: .spice, shift: 2.5))
        #expect(recipe.flavor?.salt == 4)
        #expect(recipe.ingredients.first?.quantity == 600)
        #expect(recipe.ingredients.first?.note == nil)
    }

    @Test func lesson_belongsToItsModule_andKeepsItsSteps() async throws {
        _ = try await importer.importIfNeeded(from: source(ContentFixture()), currentVersion: nil)
        let module = try #require(try ModelContext(container).fetch(FetchDescriptor<ModuleEntity>()).first)
        #expect(module.lessons.count == 2)
        let lesson = try #require(module.lessons.first { $0.id == "path-01-l01" })
        let steps = try JSONSerialization.jsonObject(with: lesson.stepsData) as? [[String: Any]]
        #expect(steps?.count == 2)
        #expect(steps?[1]["answer"] as? Int == 1)
    }

    @Test func stages_runInOrder_quizFirst_winesLast() async throws {
        let stages = StageRecorder()
        _ = try await importer.importIfNeeded(from: source(ContentFixture()), currentVersion: nil,
                                              onStage: { stages.append($0) })
        #expect(stages.all == ContentImportStage.allCases)
    }

    // MARK: Versão

    @Test func sameVersion_importsNothing() async throws {
        _ = try await importer.importIfNeeded(from: source(ContentFixture()), currentVersion: nil)
        var changed = ContentFixture()
        changed.recipes = [ContentFixture.recipe("only")]
        let version = try await importer.importIfNeeded(from: source(changed), currentVersion: "v1")
        #expect(version == nil)
        #expect(try count(RecipeEntity.self) == 2)
    }

    @Test func newVersion_replacesRecipesLessonsGlossaryAndQuiz_withoutDuplicates() async throws {
        _ = try await importer.importIfNeeded(from: source(ContentFixture()), currentVersion: nil)
        var next = ContentFixture()
        next.version = "v2"
        next.recipes = [ContentFixture.recipe("salad")]
        next.modules = [ContentFixture.module("path-01", lessons: 3)]
        let version = try await importer.importIfNeeded(from: source(next), currentVersion: "v1")
        #expect(version == "v2")
        #expect(try count(RecipeEntity.self) == 1)
        #expect(try count(ModuleEntity.self) == 1)
        #expect(try count(LessonEntity.self) == 3)
        #expect(try count(QuizQuestionEntity.self) == 24)
        #expect(try count(GlossaryTermEntity.self) == 1)
    }

    @Test func newVersion_updatesWines_removesDroppedOnes_butKeepsProtectedAndCatalogWines() async throws {
        var first = ContentFixture()
        first.wines.append(ContentFixture.wine("kept-in-cellar", name: "Kept", vintage: nil))
        _ = try await importer.importIfNeeded(from: source(first), currentVersion: nil)
        let context = ModelContext(container)
        context.insert(WineEntity(wineKey: "from-catalog", source: "catalog"))
        try context.save()

        var next = ContentFixture()
        next.version = "v2"
        next.wines = [ContentFixture.wine("a-wine-2020", name: "A Wine", vintage: 2020, acidity: 8)]
        _ = try await importer.importIfNeeded(from: source(next), currentVersion: "v1",
                                              protectedWineKeys: ["kept-in-cellar"])

        let wines = try wines()
        #expect(Set(wines.keys) == ["a-wine-2020", "kept-in-cellar", "from-catalog"])
        #expect(wines["a-wine-2020"]?.acidity == 8)
    }

    @Test func importCutShort_throws_andTheRetryEndsWithNoDuplicates() async throws {
        var broken = ContentFixture()
        broken.skipWines = true
        await #expect(throws: (any Error).self) {
            try await importer.importIfNeeded(from: source(broken), currentVersion: nil)
        }
        let version = try await importer.importIfNeeded(from: source(ContentFixture()), currentVersion: nil)
        #expect(version == "v1")
        #expect(try count(QuizQuestionEntity.self) == 24)
        #expect(try count(RecipeEntity.self) == 2)
        #expect(try count(WineEntity.self) == 2)
    }
}
