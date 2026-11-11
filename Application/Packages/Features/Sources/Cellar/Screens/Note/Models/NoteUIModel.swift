import CoreUI
import Core
import Foundation

public struct NoteUIModel {
    var isEditing = false
    /// "29 Aug".
    var date = ""
    var title = ""
    /// "Douro · 2019".
    var subtitle = ""
    /// Yes, Maybe, No or Not yet, beside "Again".
    var again = ""
    /// On the front label, for a tasted wine.
    var coverTag: String?
    var photoFront: Data?
    var photoBack: Data?
    var note: String?
    var facts: [NoteFactUIModel] = []
    var hasReading = false
    var readingText: String?
    var structure: [NoteStructureUIModel] = []
    var pairings: [String] = []
    var wineProfile: PalateMap?
    var aromas: String?
    var verdicts: [NoteVerdictUIModel] = []
    var draftNote = ""
    var isWorking = false
    var isConfirmingDelete = false
    var errorText: String?
    var resources = NoteResourcesUIModel()
}
