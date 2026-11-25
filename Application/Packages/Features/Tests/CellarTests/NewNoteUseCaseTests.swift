import Core
import Foundation
import Testing
@testable import CoreUI

@MainActor
struct NewNoteUseCaseTests {
    /// November 2026: the vintages up to 2026 are plausible.
    private let now = Date(timeIntervalSince1970: 1_794_000_000)

    private func readLabel(_ text: LabelText?, structured: LabelFacts? = nil,
                           catalog: LabelCatalogStub = LabelCatalogStub(Labels.catalog),
                           pairer: PairerStub = PairerStub(), log: LabelReadingLog? = nil) -> ReadLabelUseCase {
        ReadLabelUseCase(reader: ReaderStub(text: text), structurer: StructurerStub(facts: structured), pairer: pairer,
                         catalog: LabelCatalogCache(catalog: catalog), now: { [now] in now }, log: log)
    }

    private func readManual(pairer: PairerStub = PairerStub()) -> ReadManualUseCase {
        ReadManualUseCase(catalog: LabelCatalogCache(catalog: LabelCatalogStub(Labels.catalog)), pairer: pairer)
    }

    /// The catalog's Ponto Forte as its label reads: the 14% the catalog did not have.
    private var pontoForteAsRead: Wine {
        var wine = Labels.pontoForte
        wine.alcohol = 14
        return wine
    }

    // MARK: CELLAR-R15 · Câmara

    @Test func CELLAR_R15_firstTime_asksTheSystem() async {
        let camera = CameraStub(.notDetermined, allows: true)
        #expect(await PrepareCameraUseCase(camera: camera).execute() == .authorized)
        #expect(await camera.requests == 1)
    }

    @Test func CELLAR_R22_refusedOnce_isNotAskedAgain() async {
        let refusing = CameraStub(.notDetermined, allows: false)
        #expect(await PrepareCameraUseCase(camera: refusing).execute() == .denied)
        let refused = CameraStub(.denied)
        #expect(await PrepareCameraUseCase(camera: refused).execute() == .denied)
        #expect(await refused.requests == 0)
    }

    // MARK: CELLAR-R17 · Leitura

    @Test func CELLAR_R17_catalogWine_isFound() async {
        let result = await readLabel(Labels.pontoForteLabel).execute(front: Data(), back: Data(), backScan: nil)
        #expect(result == .read(pontoForteAsRead))
    }

    @Test func CELLAR_R17_unknownWine_goesToTheNote_withWhatWasRead() async {
        let text = LabelText([LabelLine("Vinha Imaginária", height: 0.1), LabelLine("2022"),
                              LabelLine("Syrah", side: .back)])
        let result = await readLabel(text).execute(front: Data(), back: Data(), backScan: nil)
        guard case let .read(wine) = result else { Issue.record("\(result)"); return }
        #expect(wine.id == "vinha-imaginaria-2022")
        #expect(wine.name == "Vinha Imaginária")
        #expect(wine.vintage == 2022)
        #expect(wine.grapes == ["Syrah"])
        #expect(wine.type == "Red")
        // The map of the catalog's Syrah reds.
        #expect(wine.profile == Maps.flat(7))
    }

    @Test func CELLAR_R23a_aNameWithNothingForTheMap_isCompletedByHand() async {
        // A wine (its alcohol says so) whose label gave a name but no type, grape, region or note.
        let text = LabelText([LabelLine("Vinha Imaginária", height: 0.1), LabelLine("13% vol", side: .back)])
        let result = await readLabel(text).execute(front: Data(), back: Data(), backScan: nil)
        guard case let .incomplete(facts) = result else { Issue.record("\(result)"); return }
        #expect(facts.name == "Vinha Imaginária")
        #expect(facts.alcohol == 13)
    }

    @Test func CELLAR_R17_noNameRead_isIncomplete_withWhatWasRead() async {
        let text = LabelText([LabelLine("Syrah", side: .back), LabelLine("2022", side: .back)])
        let result = await readLabel(text).execute(front: Data(), back: Data(), backScan: nil)
        guard case let .incomplete(facts) = result else { Issue.record("\(result)"); return }
        #expect(!facts.hasName)
        #expect(facts.grapes == ["Syrah"])
    }

    @Test func CELLAR_R17_modelReading_comesFirst_parserFillsTheGaps() async {
        // The model tells the name the parser would miss; the parser still reads the grape.
        let text = LabelText([LabelLine("RAVASQUEIRA", height: 0.2), LabelLine("ponto forte", height: 0.03),
                              LabelLine("2024"), LabelLine("Syrah", side: .back)])
        let structured = LabelFacts(name: "Ponto Forte", producer: "Ravasqueira", vintage: 2024)
        let result = await readLabel(text, structured: structured).execute(front: Data(), back: Data(), backScan: nil)
        #expect(result == .read(Labels.pontoForte))
    }

    @Test func CELLAR_R17_theLog_keepsEveryStepOfTheReading() async throws {
        let log = LabelReadingLog()
        let read = ReadLabelUseCase(reader: ReaderStub(text: Labels.pontoForteLabel),
                                    structurer: StructurerStub(facts: LabelFacts(name: "Ponto Forte")),
                                    pairer: PairerStub(),
                                    catalog: LabelCatalogCache(catalog: LabelCatalogStub(Labels.catalog)),
                                    now: { [now] in now }, log: log)
        _ = await read.execute(front: Data(), back: Data(), backScan: nil)
        let entry = log.last
        #expect(entry?.front == ["Ponto Forte", "RAVASQUEIRA", "2024"])
        #expect(entry?.back == ["Syrah", "14% vol"])
        #expect(entry?.parsed?.vintage == 2024)
        #expect(entry?.structured?.name == "Ponto Forte")
        #expect(entry?.match == Labels.pontoForte.displayName)
        let text = LabelReadingLog.text(try #require(entry))
        #expect(text.contains("FRONT · 3 lines"))
        #expect(text.contains("Taken for Ponto Forte, Ravasqueira"))
    }

    @Test func CELLAR_R17_withoutTheModel_theLogSaysSo() async throws {
        let log = LabelReadingLog()
        let label = LabelText([LabelLine("Vinha Imaginária", height: 0.1), LabelLine("13% vol", side: .back)])
        let read = ReadLabelUseCase(reader: ReaderStub(text: label),
                                    structurer: StructurerStub(), pairer: PairerStub(),
                                    catalog: LabelCatalogCache(catalog: LabelCatalogStub(Labels.catalog)),
                                    now: { [now] in now }, log: log)
        _ = await read.execute(front: Data(), back: Data(), backScan: nil)
        let entry = try #require(log.last)
        #expect(entry.structured == nil)
        #expect(entry.match == nil)
        // The reason the model gave nothing, and the phone as it saw it.
        let text = LabelReadingLog.text(entry)
        #expect(text.contains("No answer: Apple Intelligence is off in Settings (appleIntelligenceNotEnabled)."))
        #expect(text.contains("iOS 26.1 · pt-PT · language supported"))
    }

    @Test func CELLAR_R21_nothingRead_orReaderFails_isFailed() async {
        #expect(await readLabel(LabelText([LabelLine("  ")])).execute(front: Data(), back: Data(), backScan: nil) == .failed)
        #expect(await readLabel(nil).execute(front: Data(), back: Data(), backScan: nil) == .failed)
    }

    // MARK: CELLAR-R21a · Não é um vinho

    /// A bag of sugar: a name in big type, "branco", a producer, a nutrition table, a best-before year.
    private let sugarBag = LabelText([
        LabelLine("SIDUL", height: 0.14), LabelLine("Açúcar Branco", height: 0.1), LabelLine("1 kg", height: 0.05),
        LabelLine("Produzido por Sidul Açúcares, Lisboa", side: .back),
        LabelLine("Hidratos de carbono 100 g 38%", side: .back), LabelLine("Consumir de preferência antes de 12/2026", side: .back)
    ])

    @Test func CELLAR_R21a_somethingElse_isNotAWine_andNeitherModelNorCatalogAreAsked() async throws {
        let log = LabelReadingLog()
        let catalog = LabelCatalogStub(Labels.catalog)
        let pairer = PairerStub()
        let result = await readLabel(sugarBag, structured: LabelFacts(name: "Açúcar Branco", type: "White"),
                                     catalog: catalog, pairer: pairer, log: log)
            .execute(front: Data(), back: Data(), backScan: nil)
        #expect(result == .notWine)
        #expect(await pairer.asked.isEmpty)
        let entry = try #require(log.last)
        #expect(entry.notWine)
        #expect(entry.structured == nil)
        #expect(LabelReadingLog.text(entry).contains("NOT A WINE"))
    }

    @Test func CELLAR_R21a_aCatalogWineScannedBefore_stillNeedsItsLabelToSayWine() async {
        // The public catalog grows with every scan: a sugar bag saved once must not be found again.
        let result = await readLabel(LabelText([LabelLine("Ponto Forte", height: 0.12), LabelLine("RAVASQUEIRA")]))
            .execute(front: Data(), back: Data(), backScan: nil)
        #expect(result == .notWine)
    }

    @Test func catalog_isReadOncePerNewNote() async {
        let catalog = LabelCatalogStub(Labels.catalog)
        let cache = LabelCatalogCache(catalog: catalog)
        let read = ReadLabelUseCase(reader: ReaderStub(text: Labels.pontoForteLabel), structurer: StructurerStub(),
                                    pairer: PairerStub(), catalog: cache, now: { [now] in now })
        _ = await read.execute(front: Data(), back: Data(), backScan: nil)
        _ = try? await ReadManualUseCase(catalog: cache, pairer: PairerStub()).execute(LabelFacts(name: "X"))
        #expect(await catalog.loads == 1)
    }

    // MARK: CELLAR-R17 · As fontes somam-se

    /// The model's reading of the Ponto Forte's back label: more than the catalog has.
    private let richReading = LabelFacts(name: "Ponto Forte", producer: "Ravasqueira", vintage: 2024,
                                         grapes: ["syrah", "Alicante Bouschet"], notes: ["Plum", "Black pepper"],
                                         pairings: ["Grilled lamb"], serving: 16...18)

    @Test func CELLAR_R17_catalogWine_gainsWhatTheLabelAdds() async {
        // The model's temperature counts only when the label prints it.
        let label = LabelText(Labels.pontoForteLabel.lines + [LabelLine("Servir a 16-18 ºC", side: .back)])
        let result = await readLabel(label, structured: richReading).execute(front: Data(), back: Data(), backScan: nil)
        guard case let .read(wine) = result else { Issue.record("\(result)"); return }
        #expect(wine.id == Labels.pontoForte.id)
        // The catalog's first, then what is new; "syrah" is the catalog's Syrah.
        #expect(wine.grapes == ["Syrah", "Alicante Bouschet"])
        #expect(wine.note == "Plum, Black pepper")
        #expect(wine.pairings == ["Grilled lamb"])
        #expect(wine.serving == 16...18)
        #expect(wine.profile == Labels.pontoForte.profile)
    }

    @Test func CELLAR_R17_aTemperatureTheLabelDoesNotPrint_andNoiseNotes_areLeftOut() async {
        var guessed = richReading
        guessed.notes = ["Plum", "Firate", "Eaten"]
        let result = await readLabel(Labels.pontoForteLabel, structured: guessed)
            .execute(front: Data(), back: Data(), backScan: nil)
        guard case let .read(wine) = result else { Issue.record("\(result)"); return }
        #expect(wine.serving == nil)
        #expect(wine.note == "Plum")
    }

    @Test func CELLAR_R17_theModel_getsEverythingFound_andAddsItsDishes() async throws {
        let pairer = PairerStub(["Roast lamb", "grilled lamb"])
        let log = LabelReadingLog()
        let result = await readLabel(Labels.pontoForteLabel, structured: richReading, pairer: pairer, log: log)
            .execute(front: Data(), back: Data(), backScan: nil)
        guard case let .read(wine) = result else { Issue.record("\(result)"); return }
        #expect(wine.pairings == ["Grilled lamb", "Roast lamb"])
        let asked = try #require(await pairer.asked.first)
        #expect(asked.pairings == ["Grilled lamb"])
        #expect(asked.note == "Plum, Black pepper")
        #expect(asked.grapes == ["Syrah", "Alicante Bouschet"])
        let text = LabelReadingLog.text(try #require(log.last))
        #expect(text.contains("PAIRINGS\nFound: Grilled lamb\nAdded by the model: Roast lamb"))
    }

    @Test func CELLAR_R17_withoutTheModel_theFoundPairingsStay_andTheLogSaysWhy() async throws {
        let log = LabelReadingLog()
        let result = await readLabel(Labels.pontoForteLabel, structured: richReading, log: log)
            .execute(front: Data(), back: Data(), backScan: nil)
        guard case let .read(wine) = result else { Issue.record("\(result)"); return }
        #expect(wine.pairings == ["Grilled lamb"])
        let text = LabelReadingLog.text(try #require(log.last))
        #expect(text.contains("Model added nothing: Apple Intelligence is off in Settings (appleIntelligenceNotEnabled)."))
    }

    @Test func CELLAR_R17_aWineWithEnoughPairings_isNotSentToTheModel() async throws {
        var known = Labels.pontoForte
        known.pairings = (1...10).map { "Dish \($0)" }
        let pairer = PairerStub(["Roast lamb"])
        let log = LabelReadingLog()
        let result = await readLabel(Labels.pontoForteLabel, catalog: LabelCatalogStub([known, Labels.alentejoSyrah]),
                                     pairer: pairer, log: log).execute(front: Data(), back: Data(), backScan: nil)
        guard case let .read(wine) = result else { Issue.record("\(result)"); return }
        #expect(wine.pairings == known.pairings)
        #expect(await pairer.asked.isEmpty)
        #expect(LabelReadingLog.text(try #require(log.last)).contains("Model not asked"))
    }

    @Test func CELLAR_R23_typedWine_alsoGetsTheModelsDishes() async throws {
        let wine = try await readManual(pairer: PairerStub(["Grilled lamb"]))
            .execute(LabelFacts(name: "ponto forte", producer: "ravasqueira", vintage: 2024))
        #expect(wine.pairings == ["Grilled lamb"])
    }

    // MARK: CELLAR-R23 · Preencher à mão

    @Test func CELLAR_R23_typedCatalogWine_isTheCatalogWine() async throws {
        let wine = try await readManual().execute(LabelFacts(name: "ponto forte", producer: "ravasqueira", vintage: 2024))
        #expect(wine == Labels.pontoForte)
    }

    @Test func CELLAR_R23_typedUnknownWine_getsTheMapOfTheWinesMostLikeIt() async throws {
        let wine = try await readManual().execute(LabelFacts(name: "Vinha Imaginária", vintage: 2022, type: "Red",
                                                             region: "alentejo", grapes: ["syrah"]))
        #expect(wine.id == "vinha-imaginaria-2022")
        #expect(wine.grapes == ["Syrah"])
        #expect(wine.region == "Alentejo")
        #expect(wine.country == "Portugal")
        #expect(wine.profile == Maps.flat(7))
    }

    @Test func CELLAR_R23_typedAppellation_givesItsRegion() async throws {
        let wine = try await readManual().execute(LabelFacts(name: "Branco", type: "White", region: "Dao"))
        #expect(wine.region == "Dão")
        #expect(wine.profile == Maps.flat(2))
    }

    @Test func CELLAR_R23a_withoutABase_thereIsNoMap() async {
        // Only the name; the type alone; a made-up region and grape (the "labubu" and "cabudi" case).
        for facts in [LabelFacts(name: "Mistério"), LabelFacts(name: "Mistério", type: "Red"),
                      LabelFacts(name: "Mistério", type: "Red", region: "Labubu", grapes: ["Cabudi"])] {
            await #expect(throws: ReadManualUseCase.Failure.noMapBasis) {
                try await readManual().execute(facts)
            }
        }
    }

    @Test func CELLAR_R23a_theTimeInOak_setsTheOakAxis() async throws {
        let wine = try await readManual().execute(LabelFacts(name: "Mistério", type: "Red", grapes: ["syrah"],
                                                             oakAging: .twelveToTwentyFour, oakWoods: ["French oak"]))
        #expect(wine.profile[.oak] == OakAging.twelveToTwentyFour.oakIntensity)
        #expect(wine.profile[.body] == 7)
        #expect(wine.oakAging == .twelveToTwentyFour)
        #expect(wine.oakWoods == ["French oak"])
        // Alone with the type, it sets the axis on the type's average.
        let oakOnly = try await readManual().execute(LabelFacts(name: "Mistério", type: "Red", oakAging: .upToSix))
        #expect(oakOnly.profile[.oak] == OakAging.upToSix.oakIntensity)
        #expect(oakOnly.profile[.body] == 7)
    }

    // MARK: CELLAR-R19 · Guardar / CELLAR-R13b

    private struct Save {
        let cellar = CellarSpy()
        let catalog = LabelCatalogStub([])
        let maps = MapsSpy(map: Maps.flat(4))
        let recalculate: RecalculateSpy
        let useCase: SaveNewNoteUseCase

        @MainActor init(now: Date) {
            recalculate = RecalculateSpy()
            useCase = SaveNewNoteUseCase(cellar: cellar, catalog: catalog, maps: maps, recalculate: recalculate,
                                         now: { now })
        }
    }

    @Test func CELLAR_R19_saveNote_keepsTheEntry_andRatesOnce() async throws {
        let save = Save(now: now)
        try await save.useCase.execute(NewNoteDraft(wine: Labels.pontoForte, status: .tasted, verdict: .maybe))
        #expect(await save.cellar.saved.map(\.wine.id) == [Labels.pontoForte.id])
        #expect(await save.catalog.scanned.map(\.id) == [Labels.pontoForte.id])
        let rated = await save.maps.rated
        #expect(rated.map(\.0) == [Labels.pontoForte.id])
        #expect(rated.map(\.1) == [.maybe])
        #expect(await save.maps.map != Maps.flat(4))
        #expect(save.recalculate.calls.isEmpty)
    }

    @Test func CELLAR_R20_addToCellar_rates_nothing() async throws {
        let save = Save(now: now)
        try await save.useCase.execute(NewNoteDraft(wine: Labels.pontoForte, status: .wantToTry))
        #expect(await save.cellar.saved.count == 1)
        #expect(await save.maps.rated.isEmpty)
    }

    @Test func CELLAR_R13b_sameWine_newVerdict_replacesTheRating() async throws {
        let save = Save(now: now)
        await save.cellar.setExisting(Entries.entry(Labels.pontoForte.id, verdict: .maybe))
        await save.maps.setHistory([MapChange(date: now, cause: .quiz, values: [:]),
                                    MapChange(date: now, cause: .rating(wineKey: Labels.pontoForte.id, verdict: .maybe), values: [:])])
        try await save.useCase.execute(NewNoteDraft(wine: Labels.pontoForte, status: .tasted, verdict: .yes))
        #expect(await save.maps.rated.isEmpty)
        #expect(save.recalculate.calls.map(\.0) == [Labels.pontoForte.id])
        #expect(save.recalculate.calls.map(\.1) == [.yes])
    }

    @Test func CELLAR_R14a_ratedOnTheHome_sameVerdict_isNotRatedAgain() async throws {
        let save = Save(now: now)
        await save.maps.setHistory([MapChange(date: now, cause: .quiz, values: [:]),
                                    MapChange(date: now, cause: .rating(wineKey: Labels.pontoForte.id, verdict: .yes), values: [:])])
        try await save.useCase.execute(NewNoteDraft(wine: Labels.pontoForte, status: .tasted, verdict: .yes))
        #expect(await save.cellar.saved.count == 1)
        #expect(await save.maps.rated.isEmpty)
        #expect(save.recalculate.calls.isEmpty)
    }

    @Test func CELLAR_R14a_ratedOnTheHome_newVerdict_replacesTheRating() async throws {
        let save = Save(now: now)
        await save.maps.setHistory([MapChange(date: now, cause: .quiz, values: [:]),
                                    MapChange(date: now, cause: .rating(wineKey: Labels.pontoForte.id, verdict: .yes), values: [:])])
        try await save.useCase.execute(NewNoteDraft(wine: Labels.pontoForte, status: .tasted, verdict: .no))
        #expect(await save.maps.rated.isEmpty)
        #expect(save.recalculate.calls.map(\.1) == [.no])
    }

    @Test func CELLAR_R13b_sameWine_sameVerdict_leavesTheMap() async throws {
        let save = Save(now: now)
        await save.cellar.setExisting(Entries.entry(Labels.pontoForte.id, verdict: .yes))
        await save.maps.setHistory([MapChange(date: now, cause: .quiz, values: [:]),
                                    MapChange(date: now, cause: .rating(wineKey: Labels.pontoForte.id, verdict: .yes), values: [:])])
        try await save.useCase.execute(NewNoteDraft(wine: Labels.pontoForte, status: .tasted, verdict: .yes))
        #expect(await save.maps.rated.isEmpty)
        #expect(save.recalculate.calls.isEmpty)
    }

    @Test func afterRedo_onlyASelectedVerdictRatesAPreviouslyTastedWine() async throws {
        let save = Save(now: now)
        await save.cellar.setExisting(Entries.entry(Labels.pontoForte.id, verdict: .yes))
        await save.maps.setHistory([MapChange(date: now, cause: .quiz, values: [:])])
        var flow = NewNoteFlow(editing: Labels.pontoForte, verdict: .yes, note: "Old note", photoFront: nil, photoBack: nil)
        flow.note = "Edited note"
        try await save.useCase.execute(try #require(flow.draft))
        #expect(await save.maps.rated.isEmpty)

        flow.pick(.yes)
        try await save.useCase.execute(try #require(flow.draft))
        #expect(await save.maps.rated.map(\.1) == [.yes])
        #expect(save.recalculate.calls.isEmpty)
    }

    @Test func CELLAR_R01b_notYetEntry_givenAVerdict_isAFirstRating() async throws {
        let save = Save(now: now)
        await save.cellar.setExisting(Entries.entry(Labels.pontoForte.id))
        try await save.useCase.execute(NewNoteDraft(wine: Labels.pontoForte, status: .tasted, verdict: .no))
        #expect(await save.maps.rated.map(\.1) == [.no])
    }
}
