import Core

@MainActor
public protocol CellarFactoryProtocol {
    func makeViewModel(onAdd: @escaping () -> Void, onNoteChange: @escaping () -> Void,
                       onEditNote: @escaping (CellarEntry, Wine) -> Void) -> CellarViewModel
}
