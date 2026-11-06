import Core

public struct HomeLessonSuggestion: Equatable, Sendable {
    public var courseID: String { course.id }
    public var lessonID: String { lesson.id }
    var course: Course
    var lesson: LessonSummary
}
