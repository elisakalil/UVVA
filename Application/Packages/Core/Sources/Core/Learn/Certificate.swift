import Foundation

/// A course finished: one per course, kept with the account; the picture is drawn each time it opens (LEARN-R22a).
public struct Certificate: Equatable, Sendable {
    public var courseID: String
    public var date: Date

    public init(courseID: String, date: Date) {
        self.courseID = courseID
        self.date = date
    }

    public var kind: CourseKind? { CourseKind(courseID: courseID) }
}
