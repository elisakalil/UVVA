import Combine
import Core
import Foundation

@MainActor
public protocol NewNoteViewModelProtocol: ObservableObject {
    var uiModel: NewNoteUIModel { get }
    /// Checks the camera, asking the system the first time (CELLAR-R15).
    func start() async
    /// The shutter: the front, then the back, which starts the reading (CELLAR-R16, R17). `photo` is kept;
    /// `reading`, the same photo at full size, is what the label is read from, when there is one. `scan` is the back
    /// label as the camera read it while moving over it, when it did.
    func capture(_ photo: Data, reading: Data?, scan: LabelScan?) async
    func tryAgain()
    func fillInByHand()
    func updateManual(_ field: NewNoteField, text: String)
    func pickType(_ type: String)
    /// The suggestions of a list field of "Fill in by hand": the words this person typed before, then the catalog's
    /// (CELLAR-R23).
    func manualChipOptions(for field: NewNoteManualChipField) async -> [String]
    /// A word typed in a field of "Fill in by hand", checked when "Add" is tapped (CELLAR-R18a).
    func validateManualChip(_ typed: String, for field: NewNoteManualChipField) async -> ChipWordResult
    func chooseManual(_ values: [String], for field: NewNoteManualChipField)
    func removeManual(_ value: String, from field: NewNoteManualChipField)
    /// The time in wood; tapping the chosen one again clears it.
    func pickOakAging(_ aging: OakAging)
    func addAward(_ award: WineAward)
    func removeAward(_ award: WineAward)
    func continueManual() async
    /// A new photo of the wine over the note, from the camera or the library (CELLAR-R24).
    func replacePhoto(_ photo: Data, side: NewNotePhotoSide)
    func answer(hasTasted: Bool)
    func pick(_ verdict: Verdict)
    /// The rating sheet: the verdict and the score from 0 to 5, or none (CELLAR-R18).
    func rate(_ verdict: Verdict, score: Int?)
    func updateNote(_ text: String)
    func chipOptions(for field: NewNoteChipField) async -> [String]
    /// A word typed for grapes, notes or pairings, checked when "Add" is tapped (CELLAR-R18a).
    func validateChip(_ typed: String, for field: NewNoteChipField) async -> ChipWordResult
    func addChip(_ value: String, to field: NewNoteChipField)
    func setIntensity(_ value: Double, for axis: PalateAxis)
    /// "Save note".
    func save() async
}

public enum NewNotePhotoSide: String, Identifiable {
    case front, back

    public var id: Self { self }
}

public extension NewNoteViewModelProtocol {
    func replacePhoto(_ photo: Data) { replacePhoto(photo, side: .front) }

    /// A photo that is kept and read as it is.
    func capture(_ photo: Data) async { await capture(photo, reading: nil, scan: nil) }

    func capture(_ photo: Data, reading: Data?) async { await capture(photo, reading: reading, scan: nil) }
}
