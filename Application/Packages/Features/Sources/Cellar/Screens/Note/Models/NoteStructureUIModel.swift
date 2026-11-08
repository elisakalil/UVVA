import Foundation

/// One line of the structure: "Body", eleven dots, "Full".
struct NoteStructureUIModel: Identifiable, Equatable {
    static let dotCount = 11

    var label: String
    /// How many of the eleven dots are filled.
    var filled: Int
    var word: String
    var id: String { label }
}
