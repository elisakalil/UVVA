import Foundation

/// One line of "Fill in by hand": its label, what was typed, and the hint when empty.
struct NewNoteManualFieldUIModel: Identifiable, Equatable {
    var field: NewNoteField
    var label: String
    var text: String
    var prompt: String
    var id: NewNoteField { field }
}
