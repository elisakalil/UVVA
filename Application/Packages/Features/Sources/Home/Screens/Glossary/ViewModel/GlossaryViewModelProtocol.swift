import Combine
import Core

@MainActor
protocol GlossaryViewModelProtocol: ObservableObject {
    var uiModel: GlossaryUIModel { get }
    func updateQuery(_ query: String)
    func selectTerm(_ term: GlossaryTerm)
    func closeDefinition()
    func handleOutsideTap(isSearchFocused: Bool)
    func close()
}
