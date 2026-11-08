import Foundation

/// A bottle of a table (FRI-R12 "Open this together", FRI-R15 the menu): the course, the wine, the axis and why,
/// and the dish.
struct TableBottleUIModel: Identifiable, Equatable {
    var id: String
    var courseText: String
    var wineName: String
    var producer: String
    var axisText: String
    var why: String
    var dishTitle: String
}
