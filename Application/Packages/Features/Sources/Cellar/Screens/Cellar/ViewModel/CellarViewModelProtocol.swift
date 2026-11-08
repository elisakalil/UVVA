import Combine

@MainActor
public protocol CellarViewModelProtocol: ObservableObject {
    associatedtype NoteModel: NoteViewModelProtocol
    var uiModel: CellarUIModel { get }
    /// The saved note open over the Cellar (CELLAR-R13).
    var note: NoteModel? { get }
    func openNote(_ wineKey: String)
    func closeNote()
    func load() async
    func selectViewMode(_ mode: CellarViewMode)
    func openFilter(_ facet: CellarFacet)
    func closeFilter()
    func pick(_ value: String)
    func clearOpenFilter()
    func clearFilters()
    func updateQuery(_ query: String)
}
