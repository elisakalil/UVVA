import CoreUI
import Core
import Foundation

public struct NoteUIModel {
    /// "Added 29 Aug".
    var addedText = ""
    /// On the front label, for a tasted wine.
    var coverTag: String?
    var photoFront: Data?
    var photoBack: Data?
    /// The wine as the Home's wine sheet shows it (HOME-R28a).
    var content: WineSheetContent?
    var note: String?
    var isWorking = false
    var isConfirmingDelete = false
    var errorText: String?
    var resources = NoteResourcesUIModel()
}
