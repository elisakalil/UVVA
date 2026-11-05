import Core

/// Bridges Home navigation requests to the application, without importing other features.
@MainActor
public struct HomeCoordinator: HomeCoordinatorProtocol {
    private let onOpenCourse: (String) -> Void
    private let onOpenLearn: (CourseKind) -> Void

    public init(onOpenCourse: @escaping (String) -> Void,
                onOpenLearn: @escaping (CourseKind) -> Void) {
        self.onOpenCourse = onOpenCourse
        self.onOpenLearn = onOpenLearn
    }

    public func openCourse(_ id: String) { onOpenCourse(id) }
    public func openLearn(_ kind: CourseKind) { onOpenLearn(kind) }
}
