import Core
import Foundation

/// What reading the label came to (CELLAR-R17, R21).
enum LabelReadResult: Equatable {
    /// The catalog has the wine, surely: straight to the note.
    case found(Wine)
    /// Not sure of the wine: "Fill in by hand", with what was read, for the person to check (decision L2).
    case unsure(LabelFacts)
    /// Nothing could be read.
    case failed
}
