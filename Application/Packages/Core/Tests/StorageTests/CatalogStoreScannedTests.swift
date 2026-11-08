import Core
import Foundation
import SwiftData
import Testing
@testable import Storage

/// A wine read on a label and not found in the catalog (CELLAR-R17, ARCHITECTURE §4.3).
struct CatalogStoreScannedTests {
    let container: ModelContainer
    let store: CatalogStore
    let scanned = Wine(id: "monte-da-urze-vinha-imaginaria-2022", name: "Vinha Imaginária", producer: "Monte da Urze",
                       vintage: 2022, type: "Red", origin: "Douro, Portugal", region: "Douro", country: "Portugal",
                       grapes: ["Touriga Nacional"], alcohol: 14, profile: PalateMap([.tannin: 7, .fruit: 6]))

    init() async throws {
        container = try AppStore.makeInMemoryContainer()
        var fixture = ContentFixture()
        fixture.wines = [ContentFixture.wine("a", name: "A", vintage: nil, acidity: 3)]
        _ = try await ContentImporter(modelContainer: container)
            .importIfNeeded(from: ContentSource(directory: try fixture.write()), currentVersion: nil)
        store = CatalogStore(modelContainer: container)
    }

    @Test func CELLAR_R17_allWines_isTheWholeCatalog() async throws {
        #expect(try await store.allWines().map(\.id) == ["a"])
    }

    @Test func CELLAR_R17_addScanned_isFoundLikeAnyCatalogWine() async throws {
        try await store.addScanned(scanned)
        let found = try #require(try await store.wines(keys: [scanned.id])[scanned.id])
        #expect(found.name == "Vinha Imaginária")
        #expect(found.producer == "Monte da Urze")
        #expect(found.vintage == 2022)
        #expect(found.grapes == ["Touriga Nacional"])
        #expect(found.alcohol == 14)
        #expect(found.profile == scanned.profile)
        #expect(found.serving == nil)
        #expect(found.note == nil)
        #expect(try await store.allWines().count == 2)
    }

    @Test func CELLAR_R17_addScanned_leavesACatalogWineAsItIs() async throws {
        var same = scanned
        same.id = "a"
        try await store.addScanned(same)
        let wine = try #require(try await store.wines(keys: ["a"])["a"])
        #expect(wine.name == "A")
        #expect(wine.profile[.acidity] == 3)
    }

    @Test func scannedWine_survivesANewBundle_andBecomesTheBundlesWhenItArrives() async throws {
        try await store.addScanned(scanned)
        var next = ContentFixture()
        next.version = "v2"
        next.wines = [ContentFixture.wine("b", name: "B", vintage: nil)]
        let importer = ContentImporter(modelContainer: container)
        _ = try await importer.importIfNeeded(from: ContentSource(directory: try next.write()), currentVersion: "v1")
        #expect(try await store.wines(keys: [scanned.id]).count == 1)

        var later = ContentFixture()
        later.version = "v3"
        later.wines = [ContentFixture.wine(scanned.id, name: "Vinha Imaginária", vintage: 2022)]
        _ = try await importer.importIfNeeded(from: ContentSource(directory: try later.write()), currentVersion: "v2")
        let entity = try #require(try ModelContext(container).fetch(FetchDescriptor<WineEntity>())
            .first { $0.wineKey == scanned.id })
        #expect(entity.source == "bundle")
    }
}
