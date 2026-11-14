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
        try await fixture.load(into: container)
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

    @Test func CELLAR_R17_addScanned_keepsItsPairings() async throws {
        var read = scanned
        read.pairings = ["Grilled lamb"]
        try await store.addScanned(read)
        #expect(try await store.wines(keys: [scanned.id])[scanned.id]?.pairings == ["Grilled lamb"])
    }

    @Test func CELLAR_R17_aWineScannedAgain_gainsWhatTheNewReadingAdded() async throws {
        var first = scanned
        first.note = "Plum"
        first.pairings = ["Grilled lamb"]
        try await store.addScanned(first)
        var again = scanned
        again.name = "Vinha Imaginaria"
        again.grapes = ["touriga nacional", "Sousão"]
        again.note = "plum, Black pepper"
        again.pairings = ["Grilled lamb", "Roast kid"]
        again.serving = 16...18
        again.profile = PalateMap([.tannin: 2])
        try await store.addScanned(again)
        let wine = try #require(try await store.wines(keys: [scanned.id])[scanned.id])
        #expect(wine.grapes == ["Touriga Nacional", "Sousão"])
        #expect(wine.note == "Plum, Black pepper")
        #expect(wine.pairings == ["Grilled lamb", "Roast kid"])
        #expect(wine.serving == 16...18)
        // The name and map stay as first read.
        #expect(wine.name == "Vinha Imaginária")
        #expect(wine.profile == scanned.profile)
        #expect(try await store.allWines().count == 2)
    }

    @Test func CELLAR_R30_aWineScannedAgain_gainsItsCertification() async throws {
        let gold = WineAward(competition: "Decanter World Wine Awards", medal: .gold, year: 2023)
        let silver = WineAward(competition: "Mundus Vini", medal: .silver, year: 2022)
        var first = scanned
        first.awards = [gold]
        first.classification = "Douro"
        try await store.addScanned(first)
        var again = scanned
        again.classification = "Douro DOC · 14% abv"
        again.designation = "Reserva"
        again.awards = [gold, silver]
        again.appellationInsight = "Portugal's oldest region."
        try await store.addScanned(again)
        let wine = try #require(try await store.wines(keys: [scanned.id])[scanned.id])
        #expect(wine.awards == [gold, silver])
        #expect(wine.designation == "Reserva")
        #expect(wine.appellation == "Douro DOC")
        #expect(wine.appellationInsight == "Portugal's oldest region.")
    }

    @Test func scannedWine_survivesANewSnapshot_andBecomesTheCatalogsWhenItArrives() async throws {
        try await store.addScanned(scanned)
        let writer = CatalogWriter(modelContainer: container)
        var next = ContentFixture()
        next.wines = [ContentFixture.wine("b", name: "B", vintage: nil)]
        try await writer.replaceAll(with: try next.catalogWines(), protecting: [])
        #expect(try await store.wines(keys: [scanned.id]).count == 1)
        #expect(try await store.wines(keys: ["a"]).isEmpty)

        var later = ContentFixture()
        later.wines = [ContentFixture.wine(scanned.id, name: "Vinha Imaginária", vintage: 2022)]
        try await writer.replaceAll(with: try later.catalogWines(), protecting: [])
        let entity = try #require(try ModelContext(container).fetch(FetchDescriptor<WineEntity>())
            .first { $0.wineKey == scanned.id })
        #expect(entity.source == "catalog")
    }

    // MARK: ARCHITECTURE §4.3 · What is read goes to the public catalog

    private func pending() async throws -> [String: CatalogWineData] {
        let all = try await CatalogWriter(modelContainer: container).pendingContributions(limit: 100)
        return Dictionary(uniqueKeysWithValues: all.map { ($0.wine.id, $0.wine) })
    }

    @Test func aScannedWine_isQueued_withAllItsReadingsAddedUp() async throws {
        try await store.addScanned(scanned)
        var again = scanned
        again.pairings = ["Roast kid"]
        try await store.addScanned(again)
        let queued = try #require(try await pending()[scanned.id])
        #expect(queued.pairings == ["Roast kid"])
        #expect(queued.grapes == ["Touriga Nacional"])
        #expect(try await pending().count == 1)
    }

    @Test func aCatalogWine_isQueued_asTheLabelShowedIt() async throws {
        var read = scanned
        read.id = "a"
        read.awards = [WineAward(competition: "Decanter World Wine Awards", medal: .gold, year: 2023)]
        try await store.addScanned(read)
        #expect(try await pending()["a"]?.awards == ["Gold · Decanter World Wine Awards · 2023"])
    }
}
