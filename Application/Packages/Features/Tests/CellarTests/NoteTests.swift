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

    private func make(_ entry: CellarEntry? = nil, save: SaveNoteSpy = SaveNoteSpy(), delete: DeleteNoteSpy = DeleteNoteSpy(),
                      onChange: @escaping (Bool) -> Void = { _ in }, onClose: @escaping () -> Void = {}) -> NoteViewModel {
        NoteViewModel(entry: entry ?? tasted, loadNote: NoteLoaderStub(), saveNote: save, deleteNote: delete,
                      onChange: onChange, onClose: onClose)
    }

    // MARK: CELLAR-R26 · Conteúdo

    @Test func CELLAR_R26_showsTheNoteAndTheFacts() {
        let model = make().uiModel
        #expect(model.title == "Ponto Forte")
        #expect(model.subtitle == "Vinho Regional Alentejano · 2024")
        #expect(model.again == "Yes")
        #expect(model.note == "Dry.")
        #expect(model.facts.map(\.label) == ["Grape", "Region", "Vintage", "Type", "Producer"])
        #expect(model.facts.first?.value == "Syrah & Viognier")
    }

    @Test func CELLAR_R26_noAlcohol_noAlcoholLine() {
        #expect(!make().uiModel.facts.contains { $0.label == "Alcohol" })
    }

    @Test func reading_comesFromTheCatalogWine() async {
        var wine = Maps.wine("ponto-forte", 9)
        wine.note = "plum, black pepper, violet."
        wine.originInsight = "A warm Alentejo red."
        let model = NoteViewModel(entry: tasted, loadNote: NoteLoaderStub(wine: wine), saveNote: SaveNoteSpy(),
                                  deleteNote: DeleteNoteSpy(), onChange: { _ in }, onClose: {})
        #expect(!model.uiModel.hasReading)
        await model.load()
        #expect(model.uiModel.hasReading)
        #expect(model.uiModel.readingText == "A warm Alentejo red.")
        #expect(model.uiModel.aromas == "Plum  ·  Black pepper  ·  Violet")
        #expect(model.uiModel.structure.map(\.label) == ["Body", "Tannin", "Acidity", "Sweetness"])
        #expect(model.uiModel.structure.first?.filled == 11)
        #expect(model.uiModel.structure.first?.word == "Full")
    }

    // MARK: CELLAR-R27 · Editar

    @Test func CELLAR_R27_save_keepsTheNewVerdictAndNote() async {
        let save = SaveNoteSpy()
        var changed = false
        let model = make(save: save, onChange: { _ in changed = true })
        model.edit()
        #expect(model.uiModel.verdicts.first { $0.isSelected }?.verdict == .yes)
        model.pick(.no)
        model.updateNote("Better with the lamb.")
        await model.save()
        #expect(save.saved.first?.1 == .no)
        #expect(save.saved.first?.2 == "Better with the lamb.")
        #expect(!model.uiModel.isEditing)
        #expect(model.uiModel.again == "No")
        #expect(model.uiModel.note == "Better with the lamb.")
        #expect(changed)
    }

    @Test func CELLAR_R27_cancel_changesNothing() async {
        let save = SaveNoteSpy()
        let model = make(save: save)
        model.edit()
        model.pick(.no)
        model.cancelEdit()
        #expect(save.saved.isEmpty)
        #expect(model.uiModel.again == "Yes")
        model.edit()
        #expect(model.uiModel.verdicts.first { $0.isSelected }?.verdict == .yes)
    }

    @Test func saveFailing_staysInEdit_withTheError() async {
        let save = SaveNoteSpy()
        save.error = CancellationError()
        let model = make(save: save)
        model.edit()
        await model.save()
        #expect(model.uiModel.isEditing)
        #expect(model.uiModel.errorText != nil)
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

    // MARK: CELLAR-R27 · Mudar o veredito recalcula o mapa

    @Test func CELLAR_R27_newVerdict_recalculatesTheMap() async throws {
        let cellar = CellarSpy(), recalculate = RecalculateSpy()
        let save = SaveNoteUseCase(cellar: cellar, maps: MapsSpy(), wines: WinesStub(wines: [:]),
                                   recalculate: recalculate, now: Date.init)
        try await save.execute(entry, verdict: .no, note: "")
        #expect(await cellar.updates.first?.1 == .no)
        #expect(recalculate.calls.first?.0 == "a")
        #expect(recalculate.calls.first?.1 == .no)
    }

    @Test func sameVerdict_onlyTheNote_leavesTheMap() async throws {
        let recalculate = RecalculateSpy()
        let save = SaveNoteUseCase(cellar: CellarSpy(), maps: MapsSpy(), wines: WinesStub(wines: [:]),
                                   recalculate: recalculate, now: Date.init)
        try await save.execute(entry, verdict: .yes, note: "Dry.")
        #expect(recalculate.calls.isEmpty)
    }

    // MARK: CELLAR-R01b · De Not yet a provado

    @Test func CELLAR_R01b_notYet_givenAVerdict_ratesOnce() async throws {
        let maps = MapsSpy(map: Maps.flat(4)), recalculate = RecalculateSpy()
        let notYet = CellarEntry(id: "a", name: "A", status: .wantToTry, createdAt: .now)
        let save = SaveNoteUseCase(cellar: CellarSpy(), maps: maps, wines: WinesStub(wines: ["a": Maps.wine("a", 9)]),
                                   recalculate: recalculate, now: Date.init)
        try await save.execute(notYet, verdict: .maybe, note: "")
        #expect(await maps.rated.map(\.0) == ["a"])
        #expect(await maps.map != Maps.flat(4))
        #expect(recalculate.calls.isEmpty)
    }

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
