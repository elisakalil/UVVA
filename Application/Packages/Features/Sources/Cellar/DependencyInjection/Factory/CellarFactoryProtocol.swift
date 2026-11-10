@MainActor
public protocol CellarFactoryProtocol {
    func makeViewModel(onAdd: @escaping () -> Void, onNoteChange: @escaping () -> Void) -> CellarViewModel
    func makeNewNote(onSaved: @escaping () -> Void, onClose: @escaping () -> Void) -> NewNoteViewModel
}
