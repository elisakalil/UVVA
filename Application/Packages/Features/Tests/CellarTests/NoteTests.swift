import Core
import Foundation
import Match
import Testing
@testable import Cellar

@MainActor
struct NoteViewModelTests {
    private let tasted = CellarEntry(id: "ponto-forte", name: "Ponto Forte", producer: "Ravasqueira", vintage: 2024,
                                     type: "Red", region: "Alentejo", origin: "Vinho Regional Alentejano, Portugal",
                                     grapes: ["Syrah", "Viognier"], status: .tasted, verdict: .yes, note: "Dry.",
                                     createdAt: .now)
    private let now = Date(timeIntervalSince1970: 1_793_000_000) // 2026

    private func make(_ entry: CellarEntry? = nil, wine: Wine? = nil, maps: MapsSpy? = nil,
                      delete: DeleteNoteSpy = DeleteNoteSpy(),
                      onChange: @escaping (Bool) -> Void = { _ in }, onClose: @escaping () -> Void = {},
                      onEdit: @escaping (CellarEntry, Wine) -> Void = { _, _ in }) -> NoteViewModel {
        NoteViewModel(entry: entry ?? tasted, loadNote: NoteLoaderStub(wine: wine), deleteNote: delete, maps: maps,
                      now: { [now] in now }, onChange: onChange, onClose: onClose, onEdit: onEdit)
    }

    // MARK: CELLAR-R26 · Conteúdo

    @Test func CELLAR_R26_showsTheWineAsTheHomeSheetDoes() throws {
        let model = make().uiModel
        let content = try #require(model.content)
        #expect(content.title == "Ponto Forte")
        #expect(content.eyebrow == "Ravasqueira")
        #expect(content.facts.map(\.label) == ["Origin", "Producer", "Style", "Vintage", "Grapes", "Notes"])
        #expect(content.facts.map(\.value) == ["Vinho Regional Alentejano, Portugal", "Ravasqueira", "Red",
                                                "2024 · 2 years", "Syrah, Viognier", ""])
        #expect(model.note == "Dry.")
        #expect(model.coverTag == "Yes")
        // No map read yet: no match.
        #expect(content.percentage == nil)
    }

    @Test func CELLAR_R26_theCatalogAndTheMap_fillTheMatchAndHowToServe() async throws {
        var wine = Maps.wine("ponto-forte", 9)
        wine.serving = 16...18
        wine.howToServe = "Just below room temperature."
        wine.pairings = ["Lamb", "Cheese"]
        let model = make(wine: wine, maps: MapsSpy(map: Maps.flat(5)))
        await model.load()
        let content = try #require(model.uiModel.content)
        #expect(content.servingTemperature == "16–18 °C")
        #expect(content.howToServe == "Just below room temperature.")
        #expect(content.pairings == "Lamb, Cheese")
        #expect(content.profile == wine.profile)
        #expect(content.percentage != nil)
        #expect(content.sharedLine != nil)
        #expect(content.apartLine != nil)
        #expect(content.palate == Maps.flat(5))
    }

    @Test func CELLAR_R26_theEntrysOwnCopy_comesBeforeTheCatalog() async throws {
        var entry = tasted
        entry.wineNotes = "Cherry"
        entry.classification = "Alentejo DOC · 13.5% abv"
        entry.pairings = ["Cheese"]
        var wine = Maps.wine("ponto-forte", 9)
        wine.note = "plum"
        wine.pairings = ["Lamb"]
        let model = make(entry, wine: wine)
        await model.load()
        let content = try #require(model.uiModel.content)
        #expect(content.facts.suffix(2).map(\.label) == ["Grapes", "Notes"])
        #expect(content.facts.suffix(2).map(\.value) == ["Syrah, Viognier", "Cherry"])
        #expect(content.pairings == "Cheese")
        #expect(content.appellation == "Alentejo DOC")
    }

    // MARK: CELLAR-R27 · Editar

    @Test func CELLAR_R27_edit_opensTheNewNote_withTheEntryAndTheWineAsShown() async throws {
        var edited: (CellarEntry, Wine)?
        var wine = Maps.wine("ponto-forte", 9)
        wine.serving = 16...18
        let model = make(wine: wine, onEdit: { edited = ($0, $1) })
        await model.load()
        model.edit()
        let (entry, shown) = try #require(edited)
        #expect(entry == tasted)
        #expect(shown.name == "Ponto Forte")
        #expect(shown.grapes == ["Syrah", "Viognier"])
        #expect(shown.serving == 16...18)
    }

    // MARK: CELLAR-R28 · Apagar

    @Test func CELLAR_R28_delete_asksFirst_thenLeaves() async {
        let delete = DeleteNoteSpy()
        var deleted = false, closed = false
        let model = make(delete: delete, onChange: { deleted = $0 }, onClose: { closed = true })
        model.askToDelete()
        #expect(model.uiModel.isConfirmingDelete)
        await model.confirmDelete()
        #expect(delete.deleted == ["ponto-forte"])
        #expect(deleted)
        #expect(closed)
    }

    @Test func CELLAR_R28_cancel_keepsTheNote() {
        let delete = DeleteNoteSpy()
        let model = make(delete: delete)
        model.askToDelete()
        model.cancelDelete()
        #expect(!model.uiModel.isConfirmingDelete)
        #expect(delete.deleted.isEmpty)
    }
}

@MainActor
struct NoteUseCaseTests {
    private let entry = CellarEntry(id: "a", name: "A", status: .tasted, verdict: .yes, createdAt: .now)

    // MARK: CELLAR-R28 · Apagar retira a avaliação

    @Test func CELLAR_R28_delete_takesTheRatingOut() async throws {
        let cellar = CellarSpy(), recalculate = RecalculateSpy()
        try await DeleteNoteUseCase(cellar: cellar, recalculate: recalculate).execute(entry)
        #expect(await cellar.deletes == ["a"])
        #expect(recalculate.calls.first?.0 == "a")
        #expect(recalculate.calls.first?.1 == nil)
    }

    @Test func delete_aNotYet_leavesTheMap() async throws {
        let recalculate = RecalculateSpy()
        let notYet = CellarEntry(id: "a", name: "A", status: .wantToTry, createdAt: .now)
        try await DeleteNoteUseCase(cellar: CellarSpy(), recalculate: recalculate).execute(notYet)
        #expect(recalculate.calls.isEmpty)
    }

    // MARK: CELLAR-R29 · Recalcular o mapa

    @Test func CELLAR_R29_rewritesTheHistoryWithoutTheRating() async throws {
        let a = Maps.wine("a", 9)
        let quiz = MapChange(date: Date(timeIntervalSince1970: 0), cause: .quiz, values: Maps.flat(4).values)
        let rated = MapChange(date: Date(timeIntervalSince1970: 1), cause: .rating(wineKey: "a", verdict: .yes),
                              values: MapUpdate.apply(.yes, wine: a.profile, to: Maps.flat(4)).map.values)
        let maps = MapsSpy(history: [quiz, rated])
        try await RecalculateMapUseCase(history: maps, rewriter: maps, wines: WinesStub(wines: ["a": a]))
            .execute(changing: "a", to: nil)
        #expect(await maps.rewritten == [[quiz]])
    }

    @Test func ratedBeforeTheLastQuiz_leavesTheMap() async throws {
        let quiz = MapChange(date: .now, cause: .quiz, values: Maps.flat(4).values)
        let maps = MapsSpy(history: [quiz])
        try await RecalculateMapUseCase(history: maps, rewriter: maps, wines: WinesStub(wines: [:]))
            .execute(changing: "a", to: .no)
        #expect(await maps.rewritten.isEmpty)
    }
}
