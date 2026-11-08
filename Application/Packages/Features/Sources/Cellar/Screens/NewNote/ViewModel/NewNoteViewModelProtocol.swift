import Combine
import Core
import Foundation

@MainActor
public protocol NewNoteViewModelProtocol: ObservableObject {
    var uiModel: NewNoteUIModel { get }
    /// Checks the camera, asking the system the first time (CELLAR-R15).
    func start() async
    /// The shutter: the front, then the back, which starts the reading (CELLAR-R16, R17).
    func capture(_ photo: Data) async
    func tryAgain()
    func fillInByHand()
    func updateManual(_ field: NewNoteField, text: String)
    func pickType(_ type: String)
    func continueManual() async
    func redo()
    func answer(hasTasted: Bool)
    func pick(_ verdict: Verdict)
    func updateNote(_ text: String)
    /// "Save note" or "Add to cellar".
    func save() async
    /// The `×` (CELLAR-R25).
    func close()
    func keepEditing()
    func discard()
}
