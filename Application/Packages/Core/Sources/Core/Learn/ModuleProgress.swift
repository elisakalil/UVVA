import Foundation

/// The persisted module cursor. `state` is the number of sequentially completed lessons.
/// The next lesson is always `state + 1`; starting or leaving it never increments state.
public struct ModuleProgress: Equatable, Sendable {
    public var courseID: String
    public var state: Int
    public var lastOpenedAt: Date?
    public var completedAt: Date?

    public init(courseID: String, state: Int = 0, lastOpenedAt: Date? = nil, completedAt: Date? = nil) {
        self.courseID = courseID
        self.state = state
        self.lastOpenedAt = lastOpenedAt
        self.completedAt = completedAt
    }
}

/// Both records are read together, on the persistence queue.
public struct LearningSnapshot: Sendable {
    public var lessons: [String: LessonProgress]
    public var modules: [String: ModuleProgress]

    public init(lessons: [String: LessonProgress], modules: [String: ModuleProgress]) {
        self.lessons = lessons
        self.modules = modules
    }
}
