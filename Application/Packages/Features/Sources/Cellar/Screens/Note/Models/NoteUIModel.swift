import CoreUI
import Core
import Foundation

public struct NoteUIModel {
    /// "Added 29 Aug".
    var addedText = ""
    /// On the front label, for a tasted wine.
    var coverTag: String?
    /// The answer to "Would you drink it again?"; nil before it is tasted.
    var verdict: Verdict?
    /// The score from 0 to 5 given with it.
    var score: Int?
    var photoFront: Data?
    var photoBack: Data?
    var isReadingPhotos = false
    var wineKey = ""
    /// The wine as the Home's wine sheet shows it (HOME-R28a).
    var content: WineSheetContent?
    var note: String?
    var isWorking = false
    var isConfirmingDelete = false
    var errorText: String?
    var resources = NoteResourcesUIModel()
}
