import Core
import Foundation
import Testing
@testable import Cellar

@MainActor
struct NewNoteUseCaseTests {
    /// November 2026: the vintages up to 2026 are plausible.
    private let now = Date(timeIntervalSince1970: 1_794_000_000)

    private func readLabel(_ text: LabelText?, structured: LabelFacts? = nil,
                           catalog: LabelCatalogStub = LabelCatalogStub(Labels.catalog)) -> ReadLabelUseCase {
        ReadLabelUseCase(reader: ReaderStub(text: text), structurer: StructurerStub(facts: structured),
                         catalog: LabelCatalogCache(catalog: catalog), now: { [now] in now })
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
        let result = await readLabel(Labels.pontoForteLabel).execute(front: Data(), back: Data())
        #expect(result == .found(Labels.pontoForte))
    }

    @Test func CELLAR_R17_unknownWine_isUnsure_withWhatWasRead() async {
        let text = LabelText([LabelLine("Vinha Imaginária", height: 0.1), LabelLine("2022"),
                              LabelLine("Syrah", side: .back)])
        let result = await readLabel(text).execute(front: Data(), back: Data())
        guard case let .unsure(facts) = result else { Issue.record("\(result)"); return }
        #expect(facts.name == "Vinha Imaginária")
        #expect(facts.vintage == 2022)
        #expect(facts.grapes == ["Syrah"])
        #expect(facts.type == "Red")
    }

    @Test func CELLAR_R17_modelReading_comesFirst_parserFillsTheGaps() async {
        // The model tells the name the parser would miss; the parser still reads the grape.
        let text = LabelText([LabelLine("RAVASQUEIRA", height: 0.2), LabelLine("ponto forte", height: 0.03),
                              LabelLine("2024"), LabelLine("Syrah", side: .back)])
        let structured = LabelFacts(name: "Ponto Forte", producer: "Ravasqueira", vintage: 2024)
        let result = await readLabel(text, structured: structured).execute(front: Data(), back: Data())
        #expect(result == .found(Labels.pontoForte))
    }

    @Test func CELLAR_R21_nothingRead_orReaderFails_isFailed() async {
        #expect(await readLabel(LabelText([LabelLine("  ")])).execute(front: Data(), back: Data()) == .failed)
        #expect(await readLabel(nil).execute(front: Data(), back: Data()) == .failed)
    }

    @Test func catalog_isReadOncePerNewNote() async {
        let catalog = LabelCatalogStub(Labels.catalog)
        let cache = LabelCatalogCache(catalog: catalog)
        let read = ReadLabelUseCase(reader: ReaderStub(text: Labels.pontoForteLabel), structurer: StructurerStub(),
                                    catalog: cache, now: { [now] in now })
        _ = await read.execute(front: Data(), back: Data())
        _ = try? await ReadManualUseCase(catalog: cache).execute(LabelFacts(name: "X"))
        #expect(await catalog.loads == 1)
    }

    // MARK: CELLAR-R23 · Preencher à mão

    @Test func CELLAR_R23_typedCatalogWine_isTheCatalogWine() async throws {
        let wine = try await ReadManualUseCase(catalog: LabelCatalogCache(catalog: LabelCatalogStub(Labels.catalog)))
            .execute(LabelFacts(name: "ponto forte", producer: "ravasqueira", vintage: 2024))
        #expect(wine == Labels.pontoForte)
    }

    @Test func CELLAR_R23_typedUnknownWine_getsTheMapOfTheWinesMostLikeIt() async throws {
        let wine = try await ReadManualUseCase(catalog: LabelCatalogCache(catalog: LabelCatalogStub(Labels.catalog)))
            .execute(LabelFacts(name: "Vinha Imaginária", vintage: 2022, type: "Red", region: "alentejo",
                                grapes: ["syrah"]))
        #expect(wine.id == "vinha-imaginaria-2022")
        #expect(wine.grapes == ["Syrah"])
        #expect(wine.region == "Alentejo")
        #expect(wine.country == "Portugal")
        #expect(wine.profile == Maps.flat(7))
    }

    @Test func CELLAR_R23_typedAppellation_givesItsRegion() async throws {
        let wine = try await ReadManualUseCase(catalog: LabelCatalogCache(catalog: LabelCatalogStub(Labels.catalog)))
            .execute(LabelFacts(name: "Branco", type: "White", region: "Dao"))
        #expect(wine.region == "Dão")
        #expect(wine.profile == Maps.flat(2))
    }

    @Test func CELLAR_R23_onlyTheName_isEnough() async throws {
        let wine = try await ReadManualUseCase(catalog: LabelCatalogCache(catalog: LabelCatalogStub(Labels.catalog)))
            .execute(LabelFacts(name: "Mistério"))
        #expect(wine.id == "misterio")
        #expect(wine.profile == Maps.flat(16.0 / 3))
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
        try await save.useCase.execute(NewNoteDraft(wine: Labels.pontoForte, status: .tasted, verdict: .yes))
        #expect(await save.maps.rated.isEmpty)
        #expect(save.recalculate.calls.map(\.0) == [Labels.pontoForte.id])
        #expect(save.recalculate.calls.map(\.1) == [.yes])
    }

    @Test func CELLAR_R13b_sameWine_sameVerdict_leavesTheMap() async throws {
        let save = Save(now: now)
        await save.cellar.setExisting(Entries.entry(Labels.pontoForte.id, verdict: .yes))
        try await save.useCase.execute(NewNoteDraft(wine: Labels.pontoForte, status: .tasted, verdict: .yes))
        #expect(await save.maps.rated.isEmpty)
        #expect(save.recalculate.calls.isEmpty)
    }

    @Test func CELLAR_R01b_notYetEntry_givenAVerdict_isAFirstRating() async throws {
        let save = Save(now: now)
        await save.cellar.setExisting(Entries.entry(Labels.pontoForte.id))
        try await save.useCase.execute(NewNoteDraft(wine: Labels.pontoForte, status: .tasted, verdict: .no))
        #expect(await save.maps.rated.map(\.1) == [.no])
    }
}
