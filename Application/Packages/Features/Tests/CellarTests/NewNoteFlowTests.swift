import Core
import Foundation
import Testing
@testable import CoreUI

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
        flow.labelRead(.read(Labels.pontoForte))
        return flow
    }

    // MARK: CELLAR-R14a · Vinho vindo da Home

    @Test func CELLAR_R14a_aKnownWine_opensOnPaper_askingIfItWasHad() {
        var flow = NewNoteFlow(wine: Labels.pontoForte)
        #expect(flow.step == .note)
        #expect(flow.wine == Labels.pontoForte)
        #expect(flow.photoFront == nil)
        #expect(flow.tasting == .asking)
        #expect(flow.ratedVerdict == nil)
        // Saved unanswered, it goes in as Not yet.
        #expect(flow.draft == NewNoteDraft(wine: Labels.pontoForte, status: .wantToTry))
        flow.answer(hasTasted: true)
        flow.pick(.maybe)
        #expect(flow.draft == NewNoteDraft(wine: Labels.pontoForte, status: .tasted, verdict: .maybe, note: ""))
    }

    @Test func CELLAR_R14a_aKnownWine_notYet_isReadyToAdd() {
        var flow = NewNoteFlow(wine: Labels.pontoForte)
        flow.answer(hasTasted: false)
        #expect(flow.tasting == .notYet)
        #expect(flow.draft == NewNoteDraft(wine: Labels.pontoForte, status: .wantToTry))
    }

    @Test func CELLAR_R14a_aWineRatedBefore_asksToRateItAgain_yesGivesANewVerdict() {
        var flow = NewNoteFlow(wine: Labels.pontoForte, ratedVerdict: .no)
        #expect(flow.tasting == .asking)
        #expect(flow.ratedVerdict == .no)
        flow.answer(hasTasted: true)
        #expect(flow.tasting == .tasted)
        #expect(flow.needsVerdict)
        flow.pick(.yes)
        #expect(flow.draft == NewNoteDraft(wine: Labels.pontoForte, status: .tasted, verdict: .yes, note: ""))
    }

    @Test func CELLAR_R14a_aWineRatedBefore_noKeepsTheVerdictItHad() {
        var flow = NewNoteFlow(wine: Labels.pontoForte, ratedVerdict: .maybe)
        flow.answer(hasTasted: false)
        #expect(flow.tasting == .keptRating)
        #expect(!flow.needsVerdict)
        #expect(flow.draft == NewNoteDraft(wine: Labels.pontoForte, status: .tasted, verdict: .maybe, note: ""))
    }

    @Test func CELLAR_R14a_aWineRatedBefore_savedUnanswered_keepsTheVerdictItHad() {
        let flow = NewNoteFlow(wine: Labels.pontoForte, ratedVerdict: .yes)
        #expect(flow.draft == NewNoteDraft(wine: Labels.pontoForte, status: .tasted, verdict: .yes, note: ""))
    }

    @Test func CELLAR_R27_aSavedNote_opensToBeEdited_withWhatItHas() throws {
        var flow = NewNoteFlow(editing: Labels.pontoForte, verdict: .maybe, note: "Plum.", photoFront: front,
                               photoBack: back)
        #expect(flow.step == .note)
        #expect(flow.tasting == .tasted)
        #expect(flow.note == "Plum.")
        flow.note = ""
        let draft = try #require(flow.draft)
        #expect(draft.verdict == .maybe)
        #expect(draft.photoFront == front)
        #expect(draft.replacesNote)
        // Not tasted yet: asked again.
        #expect(NewNoteFlow(editing: Labels.pontoForte, verdict: nil, note: nil, photoFront: nil, photoBack: nil)
            .tasting == .asking)
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

    @Test func CELLAR_R17_read_opensTheNote_askingIfTasted() {
        let flow = note()
        #expect(flow.step == .note)
        #expect(flow.wine == Labels.pontoForte)
        #expect(flow.tasting == .asking)
        // "Save note" is there already: unanswered, the wine goes in as Not yet.
        #expect(flow.draft?.status == .wantToTry)
    }

    @Test func CELLAR_R17_noName_opensFillByHand_withWhatWasRead() {
        var flow = reading()
        flow.labelRead(.nameless(LabelFacts(vintage: 2024, grapes: ["Syrah", "Alicante Bouschet"])))
        #expect(flow.step == .manual)
        #expect(flow.manual.name.isEmpty)
        #expect(!flow.canContinueManual)
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

    // MARK: CELLAR-R24 · A foto da nota

    @Test func CELLAR_R24_aNewPhoto_replacesTheFront_andKeepsTheWineAndTheAnswers() throws {
        var flow = note()
        flow.answer(hasTasted: true)
        flow.pick(.no)
        flow.note = "Too sweet."
        let wine = flow.wine
        flow.replacePhoto(Data([9]))
        #expect(flow.step == .note)
        #expect(flow.wine == wine)
        let draft = try #require(flow.draft)
        #expect(draft.photoFront == Data([9]))
        #expect(draft.photoBack == back)
        #expect(draft.verdict == .no)
        #expect(draft.note == "Too sweet.")
    }

    @Test func CELLAR_R24_aWineFromTheHome_takesItsFirstPhoto() {
        var flow = NewNoteFlow(wine: Labels.pontoForte)
        flow.replacePhoto(Data([7]))
        #expect(flow.draft?.photoFront == Data([7]))
    }

    @Test func CELLAR_R24_beforeTheNote_aPhotoIsNotReplaced() {
        var flow = NewNoteFlow()
        flow.cameraChecked(.authorized)
        flow.replacePhoto(Data([7]))
        #expect(flow.photoFront == nil)
        #expect(flow.step == .front)
    }

    // MARK: CELLAR-R18 · Já provou? / CELLAR-R20 · Nota livre opcional

    @Test func CELLAR_R20_tasted_needsAVerdict_notANote() throws {
        var flow = note()
        #expect(flow.draft?.status == .wantToTry)
        flow.answer(hasTasted: true)
        #expect(!flow.canSave)
        #expect(flow.needsVerdict)
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

    @Test func personalDetailsAreIncludedWhenSavingAnUntastedWine() throws {
        var flow = NewNoteFlow(wine: Labels.pontoForte)
        flow.addChip("  Touriga Nacional  ", to: .grapes)
        flow.addChip("touriga nacional", to: .grapes)
        flow.addChip("Blackberry", to: .notes)
        flow.addChip("Roast mushrooms", to: .pairings)
        flow.setIntensity(9, for: .fruit)
        flow.note = "Try this with dinner"

        let draft = try #require(flow.draft)
        #expect(draft.status == .wantToTry)
        #expect(draft.note == "Try this with dinner")
        #expect(draft.wine.grapes == Labels.pontoForte.grapes + ["Touriga Nacional"])
        #expect(draft.wine.note?.contains("Blackberry") == true)
        #expect(draft.wine.pairings.last == "Roast mushrooms")
        #expect(draft.wine.profile[.fruit] == 9)
        #expect(draft.originalWine == Labels.pontoForte)
    }

    @Test func chipOptionsGroupCaseVariantsAndRankCommonSuggestionsFirst() {
        var first = Labels.pontoForte
        first.note = "Cedar, plum."
        var second = Labels.alentejoSyrah
        second.note = "cedar, blackberry."

        #expect(NewNoteChipField.notes.options(in: [first, second]) == ["Cedar", "blackberry", "plum"])
    }
}
