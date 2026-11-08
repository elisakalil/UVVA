import Foundation

/// One value in a filter's sheet, with how many bottles it would show.
struct CellarFilterOptionUIModel: Identifiable, Equatable {
    var value: String
    var count: String
    var isSelected: Bool
    /// No bottle has it with the other filters on; it stays listed, faded.
    var isDimmed: Bool
    var id: String { value }
}
