import Core
import Foundation
import SwiftData
import Testing
@testable import Storage

/// A note deleted takes its scanned wine with it (CELLAR-R28).
struct CatalogStoreForgetTests {
    let container: ModelContainer
    let store: CatalogStore
    let scanned = Wine(id: "casa-santos-leia-colossal-2023", name: "COLOSSAL", producer: "CASA SANTOS LEIA",
                       vintage: 2023, origin: "Lisboa, Portugal", profile: PalateMap([.tannin: 7]),
                       note: "Firate, Pe, Eaten")

    init() async throws {
        container = try AppStore.makeInMemoryContainer()
        var fixture = ContentFixture()
        fixture.wines = [ContentFixture.wine("a", name: "A", vintage: nil, acidity: 3)]
        try await fixture.load(into: container)
        store = CatalogStore(modelContainer: container)
    }

    private func pending() throws -> [String] {
        try ModelContext(container).fetch(FetchDescriptor<PendingContributionEntity>()).map(\.wineKey)
    }

    @Test func CELLAR_R28_aScannedWine_leavesThePhone_andIsNotSent() async throws {
        try await store.addScanned(scanned)
        #expect(try pending() == [scanned.id])
        try await store.forgetScanned(scanned.id)
        #expect(try await store.wines(keys: [scanned.id]).isEmpty)
        #expect(try pending().isEmpty)
        #expect(try await store.allWines().map(\.id) == ["a"])
    }

    @Test func CELLAR_R28_aCatalogWine_stays_butWhatTheLabelAddedIsNotSent() async throws {
        var read = scanned
        read.id = "a"
        try await store.addScanned(read)
        try await store.forgetScanned("a")
        #expect(try await store.wines(keys: ["a"])["a"] != nil)
        #expect(try pending().isEmpty)
    }
}
