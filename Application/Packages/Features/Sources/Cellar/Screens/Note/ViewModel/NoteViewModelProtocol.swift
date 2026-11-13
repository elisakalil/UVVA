import Combine
import Core

@MainActor
public protocol NoteViewModelProtocol: ObservableObject, Identifiable {
    var uiModel: NoteUIModel { get }
    func load() async
    /// CELLAR-R27: the note opens in the new note, to be edited there.
    func edit()
    func askToDelete()
    func cancelDelete()
    func confirmDelete() async
}
