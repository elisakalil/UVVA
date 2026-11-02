import Foundation

/// A band of a list: "Reds" and "Whites" in By grape; one untitled band elsewhere.
struct CourseGroupUIModel: Identifiable, Equatable {
    var id: String
    var title: String?
    var rows: [CourseRowUIModel]
}
