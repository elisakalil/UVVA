import Core
import Foundation
import SwiftData
import Testing
@testable import Storage

/// "Save note" and "Add to cellar" on a new note (CELLAR-R19, R13b).
struct CellarStoreSaveTests {
    let container: ModelContainer
    let store: CellarStore
    let wine = Wine(id: "ravasqueira-ponto-forte-2024", name: "Ponto Forte", producer: "Ravasqueira", vintage: 2024,
                    origin: "Vinho Regional Alentejano, Portugal", region: "Alentejo", country: "Portugal",
                    grapes: ["Syrah"], alcohol: 13.5, profile: PalateMap([:]))
    let day1 = Date(timeIntervalSince1970: 1_000)
    let day2 = Date(timeIntervalSince1970: 2_000)

    init() throws {
        container = try AppStore.makeInMemoryContainer()
        store = CellarStore(modelContainer: container)
    }

    private func entries() async throws -> [CellarEntry] { try await store.entries() }

    // MARK: CELLAR-R19 · Guardar

    @Test func CELLAR_R19_saveNote_createsATastedEntryWithEverything() async throws {
        let draft = NewNoteDraft(wine: wine, status: .tasted, verdict: .maybe, note: "  Plum and pepper. ",
                                 photoFront: Data([1]), photoBack: Data([2]))
        let before = try await store.save(draft, at: day1)
        #expect(before == nil)
        let entry = try #require(try await entries().first)
        #expect(entry.id == wine.id)
        #expect(entry.status == .tasted)
        #expect(entry.verdict == .maybe)
        #expect(entry.note == "Plum and pepper.")
        #expect(entry.photoFront == Data([1]))
        #expect(entry.photoBack == Data([2]))
        #expect(entry.region == "Alentejo")
        #expect(entry.createdAt == day1)
    }

    @Test func CELLAR_R20_addToCellar_createsAWantToTryEntryWithoutVerdict() async throws {
        try await store.save(NewNoteDraft(wine: wine, status: .wantToTry, verdict: .yes), at: day1)
        let entry = try #require(try await entries().first)
        #expect(entry.status == .wantToTry)
        #expect(entry.verdict == nil)
    }

    @Test func CELLAR_R01_tastedWithoutVerdict_staysWantToTry() async throws {
        try await store.save(NewNoteDraft(wine: wine, status: .tasted), at: day1)
        #expect(try await entries().first?.status == .wantToTry)
    }

    // MARK: CELLAR-R13b · Atualizar em vez de duplicar

    @Test func CELLAR_R13b_sameWine_updatesTheOneEntry_newVerdictWins() async throws {
        try await store.save(NewNoteDraft(wine: wine, status: .tasted, verdict: .maybe), at: day1)
        let before = try await store.save(NewNoteDraft(wine: wine, status: .tasted, verdict: .yes), at: day2)
        #expect(before?.verdict == .maybe)
        let all = try await entries()
        #expect(all.count == 1)
        #expect(all.first?.verdict == .yes)
        #expect(all.first?.createdAt == day1)
        #expect(all.first?.updatedAt == day2)
    }

    @Test func CELLAR_R13b_emptyFields_doNotEraseWhatWasThere() async throws {
        try await store.save(NewNoteDraft(wine: wine, status: .tasted, verdict: .no, note: "Too oaky.",
                                          photoFront: Data([1]), photoBack: Data([2])), at: day1)
        try await store.save(NewNoteDraft(wine: wine, status: .tasted, verdict: .no, note: "   ",
                                          photoFront: Data([3])), at: day2)
        let entry = try #require(try await entries().first)
        #expect(entry.note == "Too oaky.")
        #expect(entry.photoFront == Data([3]))
        #expect(entry.photoBack == Data([2]))
    }

    @Test func CELLAR_R13b_tastedEntry_neverGoesBackToNotYet() async throws {
        try await store.save(NewNoteDraft(wine: wine, status: .tasted, verdict: .yes), at: day1)
        try await store.save(NewNoteDraft(wine: wine, status: .wantToTry), at: day2)
        let entry = try #require(try await entries().first)
        #expect(entry.status == .tasted)
        #expect(entry.verdict == .yes)
    }

    @Test func CELLAR_R01b_notYet_becomesTasted_keepingItsDate() async throws {
        try await store.save(NewNoteDraft(wine: wine, status: .wantToTry), at: day1)
        try await store.save(NewNoteDraft(wine: wine, status: .tasted, verdict: .no), at: day2)
        let entry = try #require(try await entries().first)
        #expect(entry.status == .tasted)
        #expect(entry.verdict == .no)
        #expect(entry.createdAt == day1)
    }

    @Test func CELLAR_R13a_anotherVintage_isAnotherEntry() async throws {
        var older = wine
        older.id = WineKey.make(producer: wine.producer, name: wine.name, vintage: 2023)
        older.vintage = 2023
        try await store.save(NewNoteDraft(wine: wine, status: .wantToTry), at: day1)
        try await store.save(NewNoteDraft(wine: older, status: .wantToTry), at: day2)
        #expect(try await entries().map(\.id) == [older.id, wine.id])
    }
}
