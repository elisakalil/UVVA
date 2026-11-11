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
    func chipOptions(for field: NewNoteChipField) async -> [String]
    func addChip(_ value: String, to field: NewNoteChipField)
    func setIntensity(_ value: Double, for axis: PalateAxis)
    /// "Save note".
    func save() async
}
