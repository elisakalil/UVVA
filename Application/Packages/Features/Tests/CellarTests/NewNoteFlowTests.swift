import Core
import Foundation
import Testing
@testable import Cellar

struct NewNoteFlowTests {
    private let front = Data([1])
    private let back = Data([2])

    /// Camera on, both photos taken: reading.
    private func reading() -> NewNoteFlow {
        var flow = NewNoteFlow()
        flow.cameraChecked(.authorized)
        flow.capture(front)
        flow.capture(back)
        return flow
    }

    private func note() -> NewNoteFlow {
        var flow = reading()
        flow.labelRead(.found(Labels.pontoForte))
        return flow
    }

    // MARK: CELLAR-R15 · Câmara / CELLAR-R22 · Câmara recusada

    @Test func CELLAR_R15_cameraAllowed_opensTheFrontPhoto() {
        var flow = NewNoteFlow()
        flow.cameraChecked(.authorized)
        #expect(flow.step == .front)
    }

    @Test func CELLAR_R15_notAskedYet_waitsForTheSystem() {
        var flow = NewNoteFlow()
        flow.cameraChecked(.notDetermined)
        #expect(flow.step == .checkingCamera)
    }

    @Test func CELLAR_R22_cameraRefused_showsTheCameraIsOff_andFillByHand() {
        var flow = NewNoteFlow()
        flow.cameraChecked(.denied)
        #expect(flow.step == .cameraDenied)
        flow.fillInByHand()
        #expect(flow.step == .manual)
    }

    // MARK: CELLAR-R16 · Fotos / CELLAR-R17 · Leitura

    @Test func CELLAR_R16_frontThenBack_thenReading() {
        var flow = NewNoteFlow()
        flow.cameraChecked(.authorized)
        flow.capture(front)
        #expect(flow.step == .back)
        #expect(flow.photoFront == front)
        flow.capture(back)
        #expect(flow.step == .reading)
        #expect(flow.photoBack == back)
    }

    @Test func CELLAR_R17_found_opensTheNote_askingIfTasted() {
        let flow = note()
        #expect(flow.step == .note)
        #expect(flow.wine == Labels.pontoForte)
        #expect(flow.tasting == .asking)
        #expect(!flow.canSave)
    }

    @Test func CELLAR_R17_unsure_opensFillByHand_withWhatWasRead() {
        var flow = reading()
        flow.labelRead(.unsure(LabelFacts(name: "Ponto Forte", vintage: 2024, grapes: ["Syrah", "Alicante Bouschet"])))
        #expect(flow.step == .manual)
        #expect(flow.manual.name == "Ponto Forte")
        #expect(flow.manual.vintage == "2024")
        #expect(flow.manual.grape == "Syrah, Alicante Bouschet")
        #expect(flow.photoFront == front)
    }

    // MARK: CELLAR-R21 · Rótulo não lido

    @Test func CELLAR_R21_failed_tryAgain_opensTheFrontPhotoWithoutTheOldOnes() {
        var flow = reading()
        flow.labelRead(.failed)
        #expect(flow.step == .readFailed)
        flow.tryAgain()
        #expect(flow.step == .front)
        #expect(flow.photoFront == nil)
        #expect(flow.photoBack == nil)
    }

    @Test func CELLAR_R21_failed_fillByHand_startsEmpty() {
        var flow = reading()
        flow.labelRead(.failed)
        flow.fillInByHand()
        #expect(flow.step == .manual)
        #expect(flow.manual.isEmpty)
    }

    // MARK: CELLAR-R23 · Preencher à mão

    @Test func CELLAR_R23_continue_onlyWithAName() {
        var flow = NewNoteFlow()
        flow.cameraChecked(.denied)
        flow.fillInByHand()
        #expect(!flow.canContinueManual)
        flow.manual.name = "   "
        #expect(!flow.canContinueManual)
        flow.manual.name = "Ponto Forte"
        #expect(flow.canContinueManual)
        flow.manualRead(Labels.pontoForte)
        #expect(flow.step == .note)
    }

    @Test func CELLAR_R23_typedFacts() {
        var form = NewNoteManualForm()
        form.name = " Ponto Forte "
        form.vintage = "2024"
        form.grape = "Syrah, , Alicante Bouschet"
        form.type = "Red"
        let facts = form.facts
        #expect(facts.name == "Ponto Forte")
        #expect(facts.producer == nil)
        #expect(facts.vintage == 2024)
        #expect(facts.grapes == ["Syrah", "Alicante Bouschet"])
        #expect(facts.type == "Red")
    }

    // MARK: CELLAR-R24 · Refazer as fotos

    @Test func CELLAR_R24_redo_dropsPhotosAndReading_andOpensTheFront() {
        var flow = note()
        #expect(flow.canRedo)
        flow.redo()
        #expect(flow.step == .front)
        #expect(flow.photoFront == nil)
        #expect(flow.photoBack == nil)
        #expect(flow.wine == nil)
    }

    @Test func CELLAR_R24_noPhotos_noRedo() {
        var flow = NewNoteFlow()
        flow.cameraChecked(.denied)
        flow.fillInByHand()
        flow.manual.name = "Ponto Forte"
        flow.manualRead(Labels.pontoForte)
        #expect(!flow.canRedo)
    }

    // MARK: CELLAR-R18 · Já provou? / CELLAR-R20 · Nota livre opcional

    @Test func CELLAR_R20_tasted_needsAVerdict_notANote() throws {
        var flow = note()
        flow.answer(hasTasted: true)
        #expect(!flow.canSave)
        flow.pick(.maybe)
        let draft = try #require(flow.draft)
        #expect(draft.status == .tasted)
        #expect(draft.verdict == .maybe)
        #expect(draft.note == "")
        #expect(draft.photoFront == front)
        #expect(draft.photoBack == back)
    }

    @Test func CELLAR_R18_notYet_addsToCellarWithoutVerdict() throws {
        var flow = note()
        flow.answer(hasTasted: true)
        flow.pick(.yes)
        flow.answer(hasTasted: false)
        let draft = try #require(flow.draft)
        #expect(draft.status == .wantToTry)
        #expect(draft.verdict == nil)
    }

    @Test func CELLAR_R18_verdict_onlyAfterYes() {
        var flow = note()
        flow.pick(.yes)
        #expect(flow.verdict == nil)
    }

    // MARK: CELLAR-R25 · Descartar

    @Test func CELLAR_R25_withPhotos_closeAsksFirst() {
        var flow = reading()
        #expect(flow.close() == .confirm)
        #expect(flow.isConfirmingDiscard)
        flow.keepEditing()
        #expect(!flow.isConfirmingDiscard)
        #expect(flow.step == .reading)
    }

    @Test func CELLAR_R25_nothingYet_closesStraightAway() {
        var flow = NewNoteFlow()
        flow.cameraChecked(.authorized)
        #expect(flow.close() == .close)
        #expect(!flow.isConfirmingDiscard)
    }

    @Test func CELLAR_R25_typedByHand_closeAsksFirst() {
        var flow = NewNoteFlow()
        flow.cameraChecked(.denied)
        flow.fillInByHand()
        flow.manual.producer = "Ravasqueira"
        #expect(flow.close() == .confirm)
    }
}
