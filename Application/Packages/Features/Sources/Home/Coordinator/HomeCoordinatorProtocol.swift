import Core

@MainActor
public protocol HomeCoordinatorProtocol {
    func openCourse(_ id: String)
    func openLesson(_ suggestion: HomeLessonSuggestion)
    func openLearn(_ kind: CourseKind)
}

extension HomeCoordinatorProtocol {
    public func openLesson(_ suggestion: HomeLessonSuggestion) { openCourse(suggestion.course.id) }
}
