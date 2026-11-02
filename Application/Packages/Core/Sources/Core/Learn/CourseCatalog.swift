import Foundation

/// The Learn content of the Content store.
public protocol CourseCatalog: Sendable {
    /// Every course of a tab, in its order, with its lessons but without their steps.
    func courses(_ kind: CourseKind) async throws -> [Course]
    func course(id: String) async throws -> Course?
    /// A lesson with its steps.
    func lesson(id: String) async throws -> Lesson?
}
