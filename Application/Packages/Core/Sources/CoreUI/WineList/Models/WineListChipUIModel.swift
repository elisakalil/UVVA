import Foundation

/// A chip of "What's on the table?" (WINELIST-R06).
struct WineListChipUIModel: Identifiable, Equatable {
    var id: String
    var text: String
    var isSelected: Bool
    /// "You" is always at the table.
    var isFixed = false
}
