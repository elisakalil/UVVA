import Core

/// Bridges Home navigation requests to the application, without importing other features.
@MainActor
public struct HomeCoordinator: HomeCoordinatorProtocol {
    private let onOpenLesson: ((HomeLessonSuggestion) -> Void)?
    private let onOpenCourse: (String) -> Void
    private let onOpenLearn: (CourseKind) -> Void
    private let onScan: () -> Void
    private let onOpenFriends: () -> Void
    private let onOpenLastTable: () -> Void
    private let onOpenMapHistory: () -> Void

    public init(onOpenCourse: @escaping (String) -> Void,
                onOpenLearn: @escaping (CourseKind) -> Void,
                onOpenLesson: ((HomeLessonSuggestion) -> Void)? = nil,
                onScan: @escaping () -> Void = {},
                onOpenFriends: @escaping () -> Void = {},
                onOpenLastTable: @escaping () -> Void = {},
                onOpenMapHistory: @escaping () -> Void = {}) {
        self.onOpenLastTable = onOpenLastTable
        self.onOpenMapHistory = onOpenMapHistory
        self.onScan = onScan
        self.onOpenFriends = onOpenFriends
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
    public func scan() { onScan() }
    public func openFriends() { onOpenFriends() }
    public func openLastTable() { onOpenLastTable() }
    public func openMapHistory() { onOpenMapHistory() }
}
