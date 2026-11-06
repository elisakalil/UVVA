import Core
import Testing
@testable import Home

@MainActor
struct GlossaryViewModelTests {
    private let acidity = GlossaryTerm(term: "Acidity", pronunciation: "", definition: "Freshness")
    private let fermentation = GlossaryTerm(term: "Alcoholic fermentation", pronunciation: "", definition: "Yeasts at work")
    private let botrytis = GlossaryTerm(term: "Botrytis", pronunciation: "", definition: "A fungus", aka: "Noble rot")
    private let rose = GlossaryTerm(term: "Rosé", pronunciation: "", definition: "A pink wine")

    private var terms: [GlossaryTerm] { [rose, botrytis, fermentation, acidity] }

    @Test func opensHomeTermWithAlphabeticalLandscape() {
        let model = GlossaryViewModel(terms: terms, initialTerm: botrytis, onClose: {})
        #expect(model.uiModel.selectedTerm == botrytis)
        #expect(model.uiModel.terms.map(\.term) == [acidity, fermentation, botrytis, rose])
        #expect(model.uiModel.terms.allSatisfy { $0.isMatch })
    }

    @Test func searchMovesMatchesFirstAndClosesPreviousDetail() {
        let model = GlossaryViewModel(terms: terms, initialTerm: acidity, onClose: {})
        model.updateQuery("  NOBLE  ")
        #expect(model.uiModel.selectedTerm == nil)
        #expect(model.uiModel.terms.first?.term == botrytis)
        #expect(model.uiModel.terms.filter(\.isMatch).map(\.term) == [botrytis])

        model.updateQuery("rose")
        #expect(model.uiModel.terms.filter(\.isMatch).map(\.term) == [rose])
    }

    @Test func outsideTapResetsSearchAndDetailBeforeLeaving() {
        var closed = false
        let model = GlossaryViewModel(terms: terms, onClose: { closed = true })
        model.updateQuery("ferment")
        model.selectTerm(fermentation)
        model.handleOutsideTap(isSearchFocused: false)

        #expect(!closed)
        #expect(model.uiModel.query.isEmpty)
        #expect(model.uiModel.selectedTerm == nil)
        #expect(model.uiModel.terms.map(\.term) == [acidity, fermentation, botrytis, rose])
        #expect(model.uiModel.terms.allSatisfy { $0.isMatch })

        model.handleOutsideTap(isSearchFocused: false)
        #expect(closed)
    }

    @Test func outsideTapOnEmptyFocusedSearchStaysInGlossary() {
        var closed = false
        let model = GlossaryViewModel(terms: terms, onClose: { closed = true })
        model.handleOutsideTap(isSearchFocused: true)
        #expect(!closed)
    }

    @Test func closingDetailPreservesSearchAndNonmatchesCannotBeSelected() {
        let model = GlossaryViewModel(terms: terms, onClose: {})
        model.updateQuery("ferment")
        model.selectTerm(acidity)
        #expect(model.uiModel.selectedTerm == nil)
        model.selectTerm(fermentation)
        #expect(model.uiModel.selectedTerm == fermentation)
        model.closeDefinition()
        #expect(model.uiModel.selectedTerm == nil)
        #expect(model.uiModel.query == "ferment")
    }

    @Test func unknownSearchHasNoMatchesAndClearingRestoresAllTerms() {
        let model = GlossaryViewModel(terms: terms, onClose: {})
        model.updateQuery("unknown")
        #expect(model.uiModel.terms.allSatisfy { !$0.isMatch })
        model.updateQuery("")
        #expect(model.uiModel.terms.allSatisfy { $0.isMatch })
        #expect(model.uiModel.terms.map(\.term) == [acidity, fermentation, botrytis, rose])
    }
}
