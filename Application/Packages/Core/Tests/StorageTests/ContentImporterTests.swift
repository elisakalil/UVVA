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

    // MARK: Primeira abertura

    @Test func firstLaunch_importsEveryKind_andReturnsTheVersion() async throws {
        let version = try await importer.importIfNeeded(from: source(ContentFixture()), currentVersion: nil)
        #expect(version == "v1")
        // The wines come from the public catalog, not the bundle.
        #expect(try count(WineEntity.self) == 0)
        #expect(try count(RecipeEntity.self) == 2)
        #expect(try count(ModuleEntity.self) == 1)
        #expect(try count(LessonEntity.self) == 2)
        #expect(try count(GlossaryTermEntity.self) == 1)
        #expect(try count(QuizQuestionEntity.self) == 24)
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

    @Test func stages_runInOrder_quizFirst_lessonsLast() async throws {
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

    @Test func changingLanguage_reimportsContentUsingTheSameIDsAndKeepsPersonalProgress() async throws {
        let english = ContentFixture()
        let directory = try english.write()
        defer { try? FileManager.default.removeItem(at: directory) }
        var portuguese = english
        portuguese.version = "pt-BR-v1"
        portuguese.modules[0]["title"] = "O que é vinho"
        portuguese.terms[0]["term"] = "Acidez"
        let translation = try portuguese.write()
        defer { try? FileManager.default.removeItem(at: translation) }
        for name in ["manifest", "learn", "glossary", "recipes"] {
            try FileManager.default.copyItem(at: translation.appending(path: "\(name).json"),
                                             to: directory.appending(path: "\(name)-pt-BR.json"))
        }

        let learning = LearningStore(modelContainer: try AppStore.makeInMemoryContainer())
        let progress = LessonProgress(lessonID: "path-01-l01", courseID: "path-01", currentStep: 1,
                                      answers: [1: .options([1])], lastOpenedAt: .now)
        let certificate = Certificate(courseID: "path-01", date: .now)
        try await learning.save(progress)
        try await learning.addCertificate(certificate)

        let base = ContentSource(directory: directory, language: "en")
        let localized = ContentSource(directory: directory, language: "pt-BR")
        let englishVersion = try await importer.importIfNeeded(from: base, currentVersion: nil)
        let portugueseVersion = try await importer.importIfNeeded(from: localized, currentVersion: englishVersion)

        #expect(portugueseVersion == "pt-BR-v1")
        let context = ModelContext(container)
        let modules = try context.fetch(FetchDescriptor<ModuleEntity>())
        #expect(modules.first?.title == "O que é vinho")
        #expect(modules.first?.lessons.contains { $0.id == progress.lessonID } == true)
        #expect(try context.fetch(FetchDescriptor<GlossaryTermEntity>()).first?.term == "Acidez")
        #expect(try await learning.progress()[progress.lessonID] == progress)
        #expect(try await learning.certificates().map(\.courseID) == [certificate.courseID])

        let fallback = ContentSource(directory: directory, language: "fr")
        #expect(fallback.manifest == base.manifest)
        let restoredVersion = try await importer.importIfNeeded(from: base, currentVersion: portugueseVersion)
        #expect(restoredVersion == englishVersion)
        #expect(try ModelContext(container).fetch(FetchDescriptor<ModuleEntity>()).first?.title == "What Wine Is")
    }

    @Test func importCutShort_throws_andTheRetryEndsWithNoDuplicates() async throws {
        var broken = ContentFixture()
        broken.skipLearn = true
        await #expect(throws: (any Error).self) {
            try await importer.importIfNeeded(from: source(broken), currentVersion: nil)
        }
        let version = try await importer.importIfNeeded(from: source(ContentFixture()), currentVersion: nil)
        #expect(version == "v1")
        #expect(try count(QuizQuestionEntity.self) == 24)
        #expect(try count(RecipeEntity.self) == 2)
        #expect(try count(ModuleEntity.self) == 1)
    }
}
