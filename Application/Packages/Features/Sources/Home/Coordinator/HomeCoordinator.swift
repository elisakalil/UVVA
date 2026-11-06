import Core

/// Bridges Home navigation requests to the application, without importing other features.
@MainActor
public struct HomeCoordinator: HomeCoordinatorProtocol {
    private let onOpenLesson: ((HomeLessonSuggestion) -> Void)?
    private let onOpenCourse: (String) -> Void
    private let onOpenLearn: (CourseKind) -> Void

    public init(onOpenCourse: @escaping (String) -> Void,
                onOpenLearn: @escaping (CourseKind) -> Void,
                onOpenLesson: ((HomeLessonSuggestion) -> Void)? = nil) {
        self.onOpenLesson = onOpenLesson
        self.onOpenCourse = onOpenCourse
        self.onOpenLearn = onOpenLearn
    }

    public func openLesson(_ suggestion: HomeLessonSuggestion) {
        if let onOpenLesson { onOpenLesson(suggestion) }
        else { onOpenCourse(suggestion.course.id) }
    }
    public func openCourse(_ id: String) { onOpenCourse(id) }
    public func openLearn(_ kind: CourseKind) { onOpenLearn(kind) }
}
