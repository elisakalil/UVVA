import Foundation

/// One match of "Search modules": a course, which opens in its tab, or a lesson, which opens in the player.
public struct SearchResultUIModel: Identifiable, Equatable {
    enum Target: Equatable {
        case course(id: String)
        case lesson(courseID: String, lessonID: String)
    }

    public var id: String
    var title: String
    /// "France", "Red · Portugal", "Essentials" or "Douro · Lesson 3".
    var detail: String
    var target: Target
}
