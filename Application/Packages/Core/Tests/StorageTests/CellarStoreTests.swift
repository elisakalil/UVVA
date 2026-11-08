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

    // MARK: CELLAR-R02 · Ordem

    @Test func CELLAR_R02_entries_newestFirst() async throws {
        let older = Wine(id: "older", name: "Older", origin: "Dão, Portugal", profile: PalateMap([:]))
        try await store.addWantToTry(older, at: Date(timeIntervalSince1970: 1_000))
        try await store.addTasted(wine, verdict: .yes, at: Date(timeIntervalSince1970: 2_000))
        #expect(try await store.entries().map(\.id) == [wine.id, "older"])
    }

    @Test func entries_carryTheWineFacts_andTheVerdict() async throws {
        let douro = Wine(id: "vale-meao-2019", name: "Quinta do Vale Meão", producer: "F. Olazabal", vintage: 2019,
                         type: "Red", origin: "Douro, Portugal", region: "Douro", country: "Portugal",
                         grapes: ["Touriga Nacional"], profile: PalateMap([:]))
        try await store.addTasted(douro, verdict: .maybe)
        let entry = try #require(try await store.entries().first)
        #expect(entry.status == .tasted)
        #expect(entry.verdict == .maybe)
        #expect(entry.region == "Douro")
        #expect(entry.country == "Portugal")
        #expect(entry.vintage == 2019)
        #expect(entry.grapes == ["Touriga Nacional"])
    }

    @Test func entries_withoutRegion_fallBackOnTheOrigin() async throws {
        try await store.addWantToTry(wine)
        let entry = try #require(try await store.entries().first)
        #expect(entry.status == .wantToTry)
        #expect(entry.verdict == nil)
        #expect(entry.region == "Rioja")
        #expect(entry.country == "Spain")
    }

    // MARK: CELLAR-R27 · Editar

    @Test func CELLAR_R27_update_changesTheVerdictAndTheNote() async throws {
        try await store.addTasted(wine, verdict: .yes)
        try await store.update(wine.id, verdict: .no, note: "  Better with lamb.  ")
        let entry = try #require(try await store.entries().first)
        #expect(entry.verdict == .no)
        #expect(entry.note == "Better with lamb.")
    }

    @Test func update_aWantToTry_withAVerdict_turnsItTasted() async throws {
        try await store.addWantToTry(wine)
        try await store.update(wine.id, verdict: .maybe, note: nil)
        #expect(try await store.entries().first?.status == .tasted)
    }

    @Test func update_withAnEmptyNote_clearsIt() async throws {
        try await store.addTasted(wine, verdict: .yes)
        try await store.update(wine.id, verdict: .yes, note: "Dry.")
        try await store.update(wine.id, verdict: .yes, note: "   ")
        #expect(try await store.entries().first?.note == nil)
    }

    // MARK: CELLAR-R28 · Apagar

    @Test func CELLAR_R28_delete_removesTheEntry() async throws {
        try await store.addTasted(wine, verdict: .yes)
        try await store.delete(wine.id)
        #expect(try await store.entries().isEmpty)
    }
}
