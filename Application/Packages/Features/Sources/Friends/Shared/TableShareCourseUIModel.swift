import Foundation

/// A course on the shared pictures (FRI-R21): the course, the bottle, what to ask for at the shop, and the dish.
struct TableShareCourseUIModel: Identifiable, Equatable {
    var id: String { courseText }
    var courseText: String
    var wineText: String
    var askForText: String
    var dishText: String
}
