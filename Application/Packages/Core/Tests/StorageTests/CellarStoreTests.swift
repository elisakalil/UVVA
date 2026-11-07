import Core
import Foundation
import SwiftData
import Testing
@testable import Storage

struct CellarStoreTests {
    let container: ModelContainer
    let store: CellarStore
    let wine = Wine(id: "zuazo-gaston-finca-costanillas", name: "Finca Costanillas", producer: "Zuazo Gaston",
                    origin: "Rioja, Spain", grapes: ["Tempranillo"], alcohol: 13.5,
                    classification: "Rioja DOCa · 13.5% abv", profile: PalateMap([:]))

    init() throws {
        container = try AppStore.makeInMemoryContainer()
        store = CellarStore(modelContainer: container)
    }

    // MARK: CELLAR-R01 · Dois tipos de entrada

    @Test func CELLAR_R01_addToCellar_savesTheWineAsWantToTry() async throws {
        try await store.addWantToTry(wine)
        #expect(try await store.wineKeys() == [wine.id])
        let entry = try #require(try ModelContext(container).fetch(FetchDescriptor<CellarEntryEntity>()).first)
        #expect(entry.status == CellarEntryEntity.Status.wantToTry.rawValue)
        #expect(entry.verdict == nil)
        #expect(entry.grapes == ["Tempranillo"])
        #expect(entry.classification == "Rioja DOCa · 13.5% abv")
    }

    @Test func addToCellar_twice_keepsOneEntry() async throws {
        try await store.addWantToTry(wine)
        try await store.addWantToTry(wine)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<CellarEntryEntity>()) == 1)
    }

    @Test func addToCellar_keepsATastedEntryTasted() async throws {
        let context = ModelContext(container)
        let tasted = CellarEntryEntity(wineKey: wine.id, status: .tasted, date: .now)
        tasted.verdict = "yes"
        context.insert(tasted)
        try context.save()

        try await store.addWantToTry(wine)

        let entries = try ModelContext(container).fetch(FetchDescriptor<CellarEntryEntity>())
        #expect(entries.count == 1)
        #expect(entries.first?.status == CellarEntryEntity.Status.tasted.rawValue)
    }

    // MARK: CELLAR-R13c · Rated on the Home

    @Test func CELLAR_R13c_rating_savesTheWineAsTasted_withItsVerdict() async throws {
        try await store.addTasted(wine, verdict: .maybe)
        #expect(try await store.tastedWineKeys() == [wine.id])
        let entry = try #require(try ModelContext(container).fetch(FetchDescriptor<CellarEntryEntity>()).first)
        #expect(entry.status == CellarEntryEntity.Status.tasted.rawValue)
        #expect(entry.verdict == "maybe")
        #expect(entry.grapes == ["Tempranillo"])
    }

    @Test func CELLAR_R13c_rating_aWantToTryWine_turnsItTasted() async throws {
        try await store.addWantToTry(wine)
        #expect(try await store.tastedWineKeys().isEmpty)
        try await store.addTasted(wine, verdict: .yes)
        let entries = try ModelContext(container).fetch(FetchDescriptor<CellarEntryEntity>())
        #expect(entries.count == 1)
        #expect(entries.first?.status == CellarEntryEntity.Status.tasted.rawValue)
        #expect(entries.first?.verdict == "yes")
    }
}
