import CoreUI
import Foundation

struct NoteResourcesUIModel {
    /// The words of the wine on paper, shared with the new note.
    var paper = NotePaperResources()
    /// The rating under the photos and its sheet.
    var rating = NoteRatingResources()
    var editText = String(localized: "Edit", bundle: .module)
    var deleteText = String(localized: "Delete", bundle: .module)
    var findIcon = "magnifyingglass"
    var deleteIcon = "trash"
    var cancelText = String(localized: "Cancel", bundle: .module)
    var deleteTitleText = String(localized: "Delete this note?", bundle: .module)
    var deleteBodyText = String(localized: "It leaves your cellar and stops counting towards your palate map. This can’t be undone.", bundle: .module)
    var ratingErrorText = String(localized: "The rating wasn’t saved. Try again.", bundle: .module)
    var deleteErrorText = String(localized: "The note wasn’t deleted. Try again.", bundle: .module)

    func verdict(_ verdict: CellarTag) -> String { CellarResourcesUIModel().tag(verdict) }

    /// "Added 29 Aug", under the producer.
    func added(_ date: String) -> String { String(localized: "Added \(date)", bundle: .module) }
}
