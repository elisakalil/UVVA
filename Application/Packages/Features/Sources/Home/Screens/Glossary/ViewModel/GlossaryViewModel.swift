import Combine
import Core
import Foundation

@MainActor
final class GlossaryViewModel: GlossaryViewModelProtocol {
    @Published private(set) var uiModel: GlossaryUIModel
    private let terms: [GlossaryTerm]
    private let onClose: () -> Void

    init(terms: [GlossaryTerm], initialTerm: GlossaryTerm? = nil, onClose: @escaping () -> Void) {
        let sorted = terms.sorted { $0.term.localizedStandardCompare($1.term) == .orderedAscending }
        self.terms = sorted
        self.onClose = onClose
        uiModel = GlossaryUIModel(
            terms: sorted.map { GlossaryTermUIModel(term: $0, isMatch: true) },
            selectedTerm: initialTerm
        )
    }

    func updateQuery(_ query: String) {
        guard query != uiModel.query else { return }
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let rows = terms.map { term in
            GlossaryTermUIModel(term: term, isMatch: search.isEmpty
                || term.term.localizedStandardContains(search)
                || (term.aka?.localizedStandardContains(search) ?? false))
        }
        var model = uiModel
        model.query = query
        model.selectedTerm = nil
        model.terms = rows.filter(\.isMatch) + rows.filter { !$0.isMatch }
        uiModel = model
    }

    func selectTerm(_ term: GlossaryTerm) {
        guard uiModel.terms.contains(where: { $0.term == term && $0.isMatch }) else { return }
        uiModel.selectedTerm = term
    }

    func closeDefinition() { uiModel.selectedTerm = nil }

    /// Reset the entire selection first; a later outside tap can leave the glossary.
    func handleOutsideTap(isSearchFocused: Bool) {
        guard uiModel.selectedTerm != nil || isSearchFocused || !uiModel.query.isEmpty else {
            close()
            return
        }
        var model = uiModel
        model.query = ""
        model.selectedTerm = nil
        model.terms = terms.map { GlossaryTermUIModel(term: $0, isMatch: true) }
        uiModel = model
    }

    func close() { onClose() }
}
