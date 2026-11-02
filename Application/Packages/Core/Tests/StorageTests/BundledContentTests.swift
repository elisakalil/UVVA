import Core
import Foundation
import SwiftData
import Testing
@testable import Storage

/// Imports the real packed content (UVVA/Resources/Content) and checks it against its manifest.
struct BundledContentTests {
    static let folder = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // StorageTests
        .deletingLastPathComponent() // Tests
        .deletingLastPathComponent() // Core
        .deletingLastPathComponent() // Packages
        .deletingLastPathComponent() // Application
        .appending(path: "UVVA/Resources/Content")

    @Test(.enabled(if: FileManager.default.fileExists(atPath: folder.appending(path: "manifest.json").path)))
    func bundledContent_importsEverythingTheManifestCounts() async throws {
        let source = ContentSource(directory: Self.folder)
        let manifest = try JSONDecoder().decode(ContentManifest.self, from: Data(contentsOf: source.manifest))
        let store = FileManager.default.temporaryDirectory.appending(path: "bundled-\(UUID().uuidString)/Content.store")
        let container = try ContentStore.makeContainer(url: store)
        let importer = ContentImporter(modelContainer: container)

        let start = Date()
        let version = try await importer.importIfNeeded(from: source, currentVersion: nil)
        print("Imported bundled content in \(String(format: "%.2f", Date().timeIntervalSince(start))) s")

        let context = ModelContext(container)
        #expect(version == manifest.version)
        #expect(try context.fetchCount(FetchDescriptor<WineEntity>()) == manifest.counts["wines"])
        #expect(try context.fetchCount(FetchDescriptor<RecipeEntity>()) == manifest.counts["recipes"])
        #expect(try context.fetchCount(FetchDescriptor<ModuleEntity>()) == manifest.counts["modules"])
        #expect(try context.fetchCount(FetchDescriptor<LessonEntity>()) == manifest.counts["lessons"])
        #expect(try context.fetchCount(FetchDescriptor<GlossaryTermEntity>()) == manifest.counts["glossary"])
        #expect(try context.fetchCount(FetchDescriptor<QuizQuestionEntity>()) == manifest.counts["quiz"])

        let start2 = Date()
        let again = try await importer.importIfNeeded(from: source, currentVersion: "other")
        print("Imported again over a full store in \(String(format: "%.2f", Date().timeIntervalSince(start2))) s")
        #expect(again == manifest.version)
        #expect(try context.fetchCount(FetchDescriptor<WineEntity>()) == manifest.counts["wines"])

        let catalog = CatalogStore(modelContainer: container)
        let map = PalateMap([.acidity: 7, .fruit: 6, .body: 4, .tannin: 3])
        let start3 = Date()
        let closest = try await catalog.winesClosest(to: map, limit: 33)
        print("Ranked 10 000 wines in \(String(format: "%.2f", Date().timeIntervalSince(start3))) s")
        #expect(closest.count == 33)
        #expect(try await catalog.recipes().count == manifest.counts["recipes"])
        #expect(try await catalog.glossary().count == manifest.counts["glossary"])
    }
}
