import Combine
import Core

@MainActor
public protocol NoteViewModelProtocol: ObservableObject, Identifiable {
    var uiModel: NoteUIModel { get }
    func load() async
    func edit()
    func cancelEdit()
    func pick(_ verdict: Verdict)
    func updateNote(_ text: String)
    func save() async
    func askToDelete()
    func cancelDelete()
    func confirmDelete() async
}
