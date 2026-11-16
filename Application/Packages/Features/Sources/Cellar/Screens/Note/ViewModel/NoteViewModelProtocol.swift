import Combine
import Core

@MainActor
public protocol NoteViewModelProtocol: ObservableObject, Identifiable {
    var uiModel: NoteUIModel { get }
    func load() async
    /// CELLAR-R27: the note opens in the new note, to be edited there.
    func edit()
    func rate(_ verdict: Verdict, score: Int?, note: String) async -> Bool
    func askToDelete()
    func cancelDelete()
    func confirmDelete() async
}
