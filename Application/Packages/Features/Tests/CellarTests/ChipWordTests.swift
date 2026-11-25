import Core
import Foundation
import Testing
@testable import CoreUI

/// The model on the phone, answering the same for every word.
struct ChipWordCheckerStub: ChipWordChecking {
    var verdict: ChipWordVerdict
    func check(_ word: String, as kind: ChipWordKind) async -> ChipWordVerdict { verdict }
}

struct ChipWordValidatorTests {
    let grapes = ChipWordValidator(known: ["Touriga Nacional", "Cabernet Sauvignon", "Grüner Veltliner"], kind: .grape)
    let says = (yes: ChipWordCheckerStub(verdict: .valid), no: ChipWordCheckerStub(verdict: .invalid),
                nothing: ChipWordCheckerStub(verdict: .unavailable(reason: "Off")))

    @Test func CELLAR_R18a_aWordOfTheList_isTakenAsTheListWritesIt() async {
        #expect(await grapes.validate("touriga  nacional", checker: says.no) == .accepted("Touriga Nacional"))
        #expect(await grapes.validate("gruner-veltliner", checker: says.no) == .accepted("Grüner Veltliner"))
    }

    @Test func CELLAR_R18a_anAromaWrittenInThePhonesLanguage_isTheListsOwn() async {
        let aromas = ChipWordValidator(known: ["Guava"], kind: .aroma) { $0 == "Guava" ? "goiaba" : $0 }
        #expect(await aromas.validate("Goiaba", checker: says.no) == .accepted("Guava"))
    }

    @Test func CELLAR_R18a_aWordALetterOrTwoOff_asksDidYouMean() async {
        #expect(await grapes.validate("Cabernet Sauvingon", checker: says.yes) == .didYouMean("Cabernet Sauvignon"))
        #expect(await grapes.validate("Touriga Nacionl", checker: says.yes) == .didYouMean("Touriga Nacional"))
    }

    @Test func CELLAR_R18a_aWordTheListLacks_isTheModelsToJudge() async {
        #expect(await grapes.validate("baga", checker: says.yes) == .accepted("Baga"))
        #expect(await grapes.validate("labubu", checker: says.no) == .rejected(.unknown))
        #expect(await grapes.validate("cabudi", checker: says.nothing) == .rejected(.modelUnavailable(reason: "Off")))
        #expect(await grapes.validate("cabudi", checker: ChipWordCheckerStub(verdict: .failed(reason: "Busy")))
            == .rejected(.failed(reason: "Busy")))
    }

    @Test func CELLAR_R18a_digitsSymbolsOrOneLetter_areNoName() async {
        for typed in ["1457", "a", "Douro 2020", "www:douro", "  "] {
            #expect(await grapes.validate(typed, checker: says.yes) == .rejected(.notAWord))
        }
    }

    @Test func CELLAR_R18a_aTakenWord_isWrittenAsItsKindIs() {
        #expect(ChipWordValidator.written("touriga franca do douro", as: .grape) == "Touriga Franca do Douro")
        #expect(ChipWordValidator.written("bairrada DOC", as: .appellation) == "Bairrada DOC")
        #expect(ChipWordValidator.written("bacalhau à brás", as: .pairing) == "Bacalhau à brás")
    }
}

@MainActor
struct ChipWordViewModelTests {
    let defaults = UserDefaults(suiteName: "ChipWordViewModelTests-\(UUID().uuidString)")!

    private func make(_ verdict: ChipWordVerdict) -> NewNoteViewModel {
        NewNoteViewModel(wine: Labels.pontoForte, prepareCamera: PrepareCameraStub(.denied),
                         readLabel: ReadLabelStub(.failed), readManual: ReadManualStub(nil),
                         saveNewNote: SaveNewNoteSpy(),
                         catalog: LabelCatalogCache(catalog: LabelCatalogStub(Labels.catalog)),
                         wordChecker: ChipWordCheckerStub(verdict: verdict),
                         learnedWords: LearnedChipWords(defaults: defaults), onSaved: { _ in })
    }

    @Test func CELLAR_R18a_aWordOnlyTheModelKnew_isKept_andSuggestedNextTime() async {
        let viewModel = make(.valid)
        #expect(await viewModel.validateChip("jabuticaba", for: .notes) == .accepted("Jabuticaba"))
        #expect(await viewModel.chipOptions(for: .notes).first == "Jabuticaba")
        // Kept on the phone: a new note suggests it too.
        #expect(await make(.invalid).chipOptions(for: .notes).first == "Jabuticaba")
    }

    @Test func CELLAR_R18a_aWordOfTheList_isNotKeptAgain() async throws {
        let viewModel = make(.valid)
        let grape = try #require(await viewModel.chipOptions(for: .grapes).first)
        #expect(await viewModel.validateChip(grape.lowercased(), for: .grapes) == .accepted(grape))
        #expect(LearnedChipWords(defaults: defaults).words(.grape).isEmpty)
    }

    @Test func CELLAR_R18a_aWordTheModelTurnsDown_isNotKept() async {
        let viewModel = make(.invalid)
        #expect(await viewModel.validateManualChip("Labubu", for: .region) == .rejected(.unknown))
        #expect(LearnedChipWords(defaults: defaults).words(.region).isEmpty)
    }
}
