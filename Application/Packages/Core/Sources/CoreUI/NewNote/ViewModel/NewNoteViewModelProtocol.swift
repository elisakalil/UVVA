import Combine
import Core
import Foundation

@MainActor
public protocol NewNoteViewModelProtocol: ObservableObject {
    var uiModel: NewNoteUIModel { get }
    /// Checks the camera, asking the system the first time (CELLAR-R15).
    func start() async
    /// The shutter: the front, then the back, which starts the reading (CELLAR-R16, R17). `photo` is kept;
    /// `reading`, the same photo at full size, is what the label is read from, when there is one.
    func capture(_ photo: Data, reading: Data?) async
    func tryAgain()
    func fillInByHand()
    func updateManual(_ field: NewNoteField, text: String)
    func pickType(_ type: String)
    func continueManual() async
    /// A new photo of the wine over the note, from the camera or the library (CELLAR-R24).
    func replacePhoto(_ photo: Data)
    func answer(hasTasted: Bool)
    func pick(_ verdict: Verdict)
    func updateNote(_ text: String)
    func chipOptions(for field: NewNoteChipField) async -> [String]
    func addChip(_ value: String, to field: NewNoteChipField)
    func setIntensity(_ value: Double, for axis: PalateAxis)
    /// "Save note".
    func save() async
}

public extension NewNoteViewModelProtocol {
    /// A photo that is kept and read as it is.
    func capture(_ photo: Data) async { await capture(photo, reading: nil) }
}
