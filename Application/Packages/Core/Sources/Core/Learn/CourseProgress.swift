import Foundation

/// Progress of a module or a region/grape course (LEARN-R01, LEARN-R02).
public struct CourseProgress: Identifiable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var totalLessons: Int
    public var completedLessonNumbers: Set<Int>
    public var completedLessons: Int
    public var hasStarted: Bool
    public var lastOpenedAt: Date?
    public var current: LessonRef?

    public init(id: String, title: String, totalLessons: Int, completedLessons: Int, hasStarted: Bool,
                lastOpenedAt: Date?, current: LessonRef?, completedLessonNumbers: Set<Int>? = nil) {
        self.id = id
        self.title = title
        self.totalLessons = totalLessons
        self.completedLessonNumbers = completedLessonNumbers ?? Set(1..<(max(0, completedLessons) + 1))
        self.completedLessons = completedLessons
        self.hasStarted = hasStarted
        self.lastOpenedAt = lastOpenedAt
        self.current = current
    }

    /// SHARED-R16
    public var isInProgress: Bool { hasStarted && completedLessons < totalLessons }
}
