import Core
import Foundation

/// What reading the label came to (CELLAR-R17, R21).
enum LabelReadResult: Equatable {
    /// The wine of the catalog or, when the catalog does not have it, the wine as read on the label: straight to
    /// the note, with what there is.
    case read(Wine)
    /// A wine, but too little read for a note: no name, or nothing to draw its map from (CELLAR-R23a). "Fill in
    /// by hand", with whatever was read.
    case incomplete(LabelFacts)
    /// The photos had no text, or the reading broke.
    case failed
    /// There was text, but nothing in it says wine (CELLAR-R21a): a bag of sugar is not looked up nor mapped.
    case notWine
}
