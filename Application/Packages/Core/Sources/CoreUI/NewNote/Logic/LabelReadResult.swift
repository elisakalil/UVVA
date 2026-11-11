import Core
import Foundation

/// What reading the label came to (CELLAR-R17, R21).
enum LabelReadResult: Equatable {
    /// The wine of the catalog or, when the catalog does not have it, the wine as read on the label: straight to
    /// the note, with what there is.
    case read(Wine)
    /// No name could be read, and a note needs one: "Fill in by hand", with whatever else was read.
    case nameless(LabelFacts)
    /// The photos had no text, or the reading broke.
    case failed
}
