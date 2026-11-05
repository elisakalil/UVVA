import Core

@MainActor
public protocol HomeCoordinatorProtocol {
    func openCourse(_ id: String)
    func openLearn(_ kind: CourseKind)
}
