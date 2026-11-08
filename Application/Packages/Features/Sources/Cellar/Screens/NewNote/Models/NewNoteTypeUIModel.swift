import Foundation

/// One type to choose in "Fill in by hand" (CELLAR-R23).
struct NewNoteTypeUIModel: Identifiable, Equatable {
    /// As the catalog writes it.
    var type: String
    var label: String
    var isSelected: Bool
    var id: String { type }
}
