import Foundation

/// Keeps the lessons' progress and the certificates in the Personal store (ARCHITECTURE §2.1).
public protocol LearningRepository: Sendable {
    /// Every lesson opened, keyed by lesson id.
    func snapshot(for courses: [Course]) async throws -> LearningSnapshot
    /// Saves the lesson and module state in one transaction. Completion increments only state + 1.
    func save(_ progress: LessonProgress, in course: Course) async throws
    func progress() async throws -> [String: LessonProgress]
    /// Adds the lesson's progress or replaces it.
    func save(_ progress: LessonProgress) async throws
    func certificates() async throws -> [Certificate]
    /// One per course (LEARN-R22): a course that already has one keeps it.
    func addCertificate(_ certificate: Certificate) async throws
}
