import Core
import Foundation
import Testing
@testable import Cellar

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
    init(_ result: LabelReadResult) { self.result = result }
    func execute(front: Data, back: Data) async -> LabelReadResult {
        reads.append((front, back))
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
    let read = ReadLabelStub(.found(Labels.pontoForte))
    let manual = ReadManualStub(Labels.pontoForte)
    let save = SaveNewNoteSpy()
    let events = Events()

    @MainActor final class Events {
        var saved = 0
        var closed = 0
    }

    private func make(_ access: CameraAccess = .authorized) -> NewNoteViewModel {
        NewNoteViewModel(prepareCamera: PrepareCameraStub(access), readLabel: read, readManual: manual,
                         saveNewNote: save, onSaved: { [events] in events.saved += 1 },
                         onClose: { [events] in events.closed += 1 })
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
        #expect(viewModel.uiModel.subtitle == "Vinho Regional Alentejano · 2024")
        #expect(viewModel.uiModel.facts.contains { $0.value == "Syrah" })
        #expect(viewModel.uiModel.structure.count == 4)
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

    @Test func CELLAR_R23_unsure_fillsTheForm_continueReadsIt() async {
        read.result = .unsure(LabelFacts(name: "Ponto Forte", producer: "Ravasqueira"))
        let viewModel = make()
        await viewModel.start()
        await viewModel.capture(Data([1]))
        await viewModel.capture(Data([2]))
        #expect(viewModel.uiModel.step == .manual)
        #expect(viewModel.uiModel.manualFields.first?.text == "Ponto Forte")
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

    // MARK: CELLAR-R24 / R25

    @Test func CELLAR_R24_redo_opensTheFrontAgain() async {
        let viewModel = await atTheNote()
        #expect(viewModel.uiModel.canRedo)
        viewModel.redo()
        #expect(viewModel.uiModel.step == .front)
        #expect(viewModel.uiModel.photoFront == nil)
    }

    @Test func CELLAR_R25_close_asks_discardCloses_withoutSaving() async {
        let viewModel = await atTheNote()
        viewModel.close()
        #expect(viewModel.uiModel.isConfirmingDiscard)
        #expect(events.closed == 0)
        viewModel.keepEditing()
        #expect(!viewModel.uiModel.isConfirmingDiscard)
        viewModel.close()
        viewModel.discard()
        #expect(events.closed == 1)
        #expect(save.saved.isEmpty)
    }

    @Test func CELLAR_R25_nothingTaken_closesStraightAway() async {
        let viewModel = make()
        await viewModel.start()
        viewModel.close()
        #expect(events.closed == 1)
    }
}
