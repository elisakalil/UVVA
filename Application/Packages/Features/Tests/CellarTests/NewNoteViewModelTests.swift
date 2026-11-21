import Core
import Foundation
import Testing
@testable import CoreUI

@MainActor
final class PrepareCameraStub: PrepareCameraUseCaseProtocol {
    var access: CameraAccess
    init(_ access: CameraAccess) { self.access = access }
    func execute() async -> CameraAccess { access }
}

@MainActor
final class ReadLabelStub: ReadLabelUseCaseProtocol {
    var result: LabelReadResult
    private(set) var reads: [(Data, Data)] = []
    private(set) var scans: [LabelScan?] = []
    init(_ result: LabelReadResult) { self.result = result }
    func execute(front: Data, back: Data, backScan: LabelScan?,
                 onStage: @MainActor (LabelReadStage) -> Void) async -> LabelReadResult {
        reads.append((front, back))
        scans.append(backScan)
        return result
    }
}

@MainActor
final class ReadManualStub: ReadManualUseCaseProtocol {
    var wine: Wine?
    private(set) var facts: [LabelFacts] = []
    init(_ wine: Wine?) { self.wine = wine }
    func execute(_ facts: LabelFacts) async throws -> Wine {
        self.facts.append(facts)
        guard let wine else { throw ReaderStub.Failure.offline }
        return wine
    }
}

@MainActor
final class SaveNewNoteSpy: SaveNewNoteUseCaseProtocol {
    var error: Error?
    private(set) var saved: [NewNoteDraft] = []
    func execute(_ draft: NewNoteDraft) async throws {
        if let error { throw error }
        saved.append(draft)
    }
}

@MainActor
struct NewNoteViewModelTests {
    let read = ReadLabelStub(.read(Labels.pontoForte))
    let manual = ReadManualStub(Labels.pontoForte)
    let save = SaveNewNoteSpy()
    let events = Events()

    @MainActor final class Events {
        var saved = 0
    }

    private func make(_ access: CameraAccess = .authorized) -> NewNoteViewModel {
        NewNoteViewModel(prepareCamera: PrepareCameraStub(access), readLabel: read, readManual: manual,
                         saveNewNote: save, onSaved: { [events] _ in events.saved += 1 })
    }

    // MARK: CELLAR-R14a

    @Test func CELLAR_R14a_aWineFromTheHome_skipsTheCamera_andSavesWithItsVerdict() async {
        let viewModel = NewNoteViewModel(wine: Labels.pontoForte,
                                         prepareCamera: PrepareCameraStub(.denied), readLabel: read, readManual: manual,
                                         saveNewNote: save, onSaved: { [events] _ in events.saved += 1 })
        await viewModel.start()
        #expect(viewModel.uiModel.step == .note)
        #expect(viewModel.uiModel.title == Labels.pontoForte.name)
        #expect(viewModel.uiModel.tasting == .asking)
        #expect(!viewModel.uiModel.isRatedBefore)
        viewModel.answer(hasTasted: true)
        viewModel.pick(.yes)
        #expect(viewModel.uiModel.canSave)
        await viewModel.save()
        #expect(save.saved.map(\.verdict) == [.yes])
        #expect(events.saved == 1)
    }

    @Test func CELLAR_R14a_aWineRatedBefore_asksToRateItAgain_andNoKeepsItsVerdict() async {
        let viewModel = NewNoteViewModel(wine: Labels.pontoForte, ratedVerdict: .maybe,
                                         prepareCamera: PrepareCameraStub(.denied), readLabel: read, readManual: manual,
                                         saveNewNote: save, onSaved: { [events] _ in events.saved += 1 })
        await viewModel.start()
        #expect(viewModel.uiModel.isRatedBefore)
        viewModel.answer(hasTasted: false)
        #expect(viewModel.uiModel.tasting == .keptRating)
        await viewModel.save()
        #expect(save.saved.map(\.verdict) == [.maybe])
        #expect(save.saved.map(\.status) == [.tasted])
    }

    // MARK: CELLAR-R15 / R22

    @Test func CELLAR_R15_start_opensTheFrontPhoto() async {
        let viewModel = make()
        await viewModel.start()
        #expect(viewModel.uiModel.step == .front)
        #expect(viewModel.uiModel.captureTitle == viewModel.uiModel.resources.frontTitleText)
        #expect(viewModel.uiModel.captureSteps.map(\.isCurrent) == [true, false])
    }

    @Test func CELLAR_R22_cameraOff_showsTheMessage() async {
        let viewModel = make(.denied)
        await viewModel.start()
        #expect(viewModel.uiModel.step == .cameraDenied)
    }

    // MARK: CELLAR-R16 / R17

    @Test func CELLAR_R17_bothPhotos_areRead_andTheWineShows() async {
        let viewModel = make()
        await viewModel.start()
        await viewModel.capture(Data([1]))
        #expect(viewModel.uiModel.step == .back)
        #expect(viewModel.uiModel.captureSteps.map(\.isDone) == [true, false])
        await viewModel.capture(Data([2]))
        #expect(read.reads.map(\.0) == [Data([1])])
        #expect(read.reads.map(\.1) == [Data([2])])
        #expect(viewModel.uiModel.step == .note)
        #expect(viewModel.uiModel.title == "Ponto Forte")
        #expect(viewModel.uiModel.wine?.producer == "Ravasqueira")
        #expect(viewModel.uiModel.facts.map(\.label) == ["Style", "Vintage"])
        #expect(viewModel.uiModel.wine?.grapes.contains("Syrah") == true)
        #expect(viewModel.uiModel.wine?.profile.values.count == PalateAxis.allCases.count)
        #expect(viewModel.uiModel.findURL != nil)
    }

    @Test func CELLAR_R21_failedReading_showsTheMessage_tryAgainOpensTheFront() async {
        read.result = .failed
        let viewModel = make()
        await viewModel.start()
        await viewModel.capture(Data([1]))
        await viewModel.capture(Data([2]))
        #expect(viewModel.uiModel.step == .readFailed)
        viewModel.tryAgain()
        #expect(viewModel.uiModel.step == .front)
    }

    // MARK: CELLAR-R23 · Preencher à mão

    @Test func CELLAR_R23_noName_fillsTheForm_continueReadsIt() async {
        read.result = .nameless(LabelFacts(producer: "Ravasqueira"))
        let viewModel = make()
        await viewModel.start()
        await viewModel.capture(Data([1]))
        await viewModel.capture(Data([2]))
        #expect(viewModel.uiModel.step == .manual)
        #expect(viewModel.uiModel.manualFields.map(\.text).contains("Ravasqueira"))
        #expect(!viewModel.uiModel.canContinue)
        viewModel.updateManual(.name, text: "Ponto Forte")
        #expect(viewModel.uiModel.canContinue)
        viewModel.updateManual(.vintage, text: "20x24")
        viewModel.pickType("Red")
        await viewModel.continueManual()
        #expect(manual.facts.first?.vintage == 2024)
        #expect(manual.facts.first?.type == "Red")
        #expect(viewModel.uiModel.step == .note)
    }

    @Test func CELLAR_R23_emptyName_cannotContinue() async {
        let viewModel = make(.denied)
        await viewModel.start()
        viewModel.fillInByHand()
        #expect(!viewModel.uiModel.canContinue)
        await viewModel.continueManual()
        #expect(manual.facts.isEmpty)
        viewModel.updateManual(.name, text: "Ponto Forte")
        #expect(viewModel.uiModel.canContinue)
    }

    @Test func CELLAR_R23_readingFails_showsAnError_andStays() async {
        manual.wine = nil
        let viewModel = make(.denied)
        await viewModel.start()
        viewModel.fillInByHand()
        viewModel.updateManual(.name, text: "Ponto Forte")
        await viewModel.continueManual()
        #expect(viewModel.uiModel.step == .manual)
        #expect(viewModel.uiModel.errorText == viewModel.uiModel.resources.manualErrorText)
    }

    @Test func pickingTheChosenTypeAgain_clearsIt() async {
        let viewModel = make(.denied)
        await viewModel.start()
        viewModel.fillInByHand()
        viewModel.pickType("White")
        #expect(viewModel.uiModel.types.first { $0.isSelected }?.type == "White")
        viewModel.pickType("White")
        #expect(!viewModel.uiModel.types.contains { $0.isSelected })
    }

    // MARK: CELLAR-R19 / R20 · Guardar

    private func atTheNote() async -> NewNoteViewModel {
        let viewModel = make()
        await viewModel.start()
        await viewModel.capture(Data([1]))
        await viewModel.capture(Data([2]))
        return viewModel
    }

    @Test func CELLAR_R19_saveNote_savesTheDraft_andTellsTheCellar() async {
        let viewModel = await atTheNote()
        viewModel.answer(hasTasted: true)
        #expect(!viewModel.uiModel.canSave)
        viewModel.pick(.maybe)
        viewModel.updateNote("Plum and pepper.")
        #expect(viewModel.uiModel.canSave)
        await viewModel.save()
        #expect(save.saved.map(\.verdict) == [.maybe])
        #expect(save.saved.map(\.note) == ["Plum and pepper."])
        #expect(save.saved.map(\.photoFront) == [Data([1])])
        #expect(events.saved == 1)
    }

    @Test func CELLAR_R20_addToCellar_savesWantToTry() async {
        let viewModel = await atTheNote()
        viewModel.answer(hasTasted: false)
        await viewModel.save()
        #expect(save.saved.map(\.status) == [.wantToTry])
        #expect(events.saved == 1)
    }

    @Test func saveFails_showsAnError_andKeepsTheNote() async {
        save.error = ReaderStub.Failure.offline
        let viewModel = await atTheNote()
        viewModel.answer(hasTasted: false)
        await viewModel.save()
        #expect(events.saved == 0)
        #expect(viewModel.uiModel.step == .note)
        #expect(viewModel.uiModel.errorText == viewModel.uiModel.resources.saveErrorText)
    }

    @Test func CELLAR_R19_unanswered_savesAsNotYet() async {
        let viewModel = await atTheNote()
        await viewModel.save()
        #expect(save.saved.map(\.status) == [.wantToTry])
        #expect(events.saved == 1)
    }

    @Test func CELLAR_R20_yesWithoutAVerdict_asksForIt_andSavesNothing() async {
        let viewModel = await atTheNote()
        viewModel.answer(hasTasted: true)
        await viewModel.save()
        #expect(save.saved.isEmpty)
        #expect(viewModel.uiModel.errorText == viewModel.uiModel.resources.verdictRequiredText)
        viewModel.pick(.yes)
        #expect(viewModel.uiModel.errorText == nil)
        await viewModel.save()
        #expect(save.saved.map(\.verdict) == [.yes])
    }

    @Test func CELLAR_R17_theLabelIsReadFromTheFullSizeCopies_andTheLightOnesAreKept() async throws {
        let viewModel = make()
        await viewModel.start()
        await viewModel.capture(Data([1]), reading: Data([11]))
        await viewModel.capture(Data([2]), reading: Data([22]))
        let reads = read.reads
        #expect(reads.count == 1)
        #expect(reads.first?.0 == Data([11]))
        #expect(reads.first?.1 == Data([22]))
        // The note keeps the light photo.
        #expect(viewModel.uiModel.photoFront == Data([1]))
    }

    @Test func CELLAR_R17_theBackLabelsScan_goesWithItsPhotoToTheReading() async throws {
        let viewModel = make()
        await viewModel.start()
        var scan = LabelScan()
        scan.add([LabelLine("Castas: Touriga Nacional", side: .back)])
        await viewModel.capture(Data([1]), reading: nil, scan: nil)
        await viewModel.capture(Data([2]), reading: nil, scan: scan)
        #expect(read.scans == [scan])
    }

    @Test func CELLAR_R17_theScan_decidesHowSureEachBackLineIs_andThePhotoIsOneFrameMore() {
        var scan = LabelScan()
        scan.add([LabelLine("Castas: Touriga Nacional", side: .back, confidence: 0.4),
                  LabelLine("Trophy SENTENA COM.", side: .back, confidence: 1)])
        scan.add([LabelLine("Castas: Touriga Nacional", side: .back, confidence: 0.4)])
        let photos = LabelText([LabelLine("COLOSSAL", side: .front, confidence: 1),
                                LabelLine("Castas: Touriga Nacional", side: .back, confidence: 0.5)])
        let text = ReadLabelUseCase.merging(photos, backScan: scan)
        #expect(text.front.map(\.text) == ["COLOSSAL"])
        #expect(text.back.map(\.text) == ["Castas: Touriga Nacional", "Trophy SENTENA COM."])
        #expect(text.back.map(\.confidence) == [0.8, 0.4])
        // No scan: the photos as they were read.
        #expect(ReadLabelUseCase.merging(photos, backScan: nil) == photos)
        #expect(ReadLabelUseCase.merging(photos, backScan: LabelScan()) == photos)
    }

    // MARK: CELLAR-R24

    @Test func CELLAR_R24_theNoteShowsBothPhotos_andReplacesEachIndependently() async {
        let viewModel = await atTheNote()
        #expect(viewModel.uiModel.photoFront == Data([1]))
        #expect(viewModel.uiModel.photoBack == Data([2]))
        viewModel.replacePhoto(Data([5]))
        #expect(viewModel.uiModel.photoFront == Data([5]))
        #expect(viewModel.uiModel.photoBack == Data([2]))
        viewModel.replacePhoto(Data([6]), side: .back)
        #expect(viewModel.uiModel.photoFront == Data([5]))
        #expect(viewModel.uiModel.photoBack == Data([6]))
        #expect(viewModel.uiModel.step == .note)
    }
}

struct NewNoteMatchLinesTests {
    /// A map given by its positions on the ruler, as the lines read it (QUIZ-R04a).
    private func map(_ highs: [PalateAxis: Double]) -> PalateMap {
        PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map {
            ($0, WineRuler.value(atPosition: highs[$0] ?? 3, on: $0))
        }))
    }

    @Test func HOME_R10b_theNewNote_saysHowTheWineSitsWithTheMap_asTheWineSheetDoes() throws {
        var wine = Maps.wine("w", 3)
        wine.profile = map([.body: 9, .oak: 9])
        let palate = map([.body: 8, .acidity: 8])
        let content = NotePaperContent(wine: wine, palate: palate)
        let sheet = PalateMatchUIModel(wine: wine.profile, palate: palate)
        #expect(content.match == sheet.percent)
        #expect(content.matchShared == sheet.shared)
        #expect(content.matchApart == sheet.apart)
        #expect(content.matchShared == "High in body, like your map.")
        #expect(content.matchApart == "More oak than you usually drink.")
    }

    @Test func HOME_R10b_withoutAMap_theNewNoteHasNoLines() {
        let content = NotePaperContent(wine: Maps.wine("w", 5), palate: nil)
        #expect(content.match == nil)
        #expect(content.matchShared == nil)
        #expect(content.matchApart == nil)
    }
}
