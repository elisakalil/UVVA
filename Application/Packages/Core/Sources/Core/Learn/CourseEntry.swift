import Foundation

/// Where a course's button opens (LEARN-R11): a lesson, at its cover or at a saved step.
public struct CourseEntry: Equatable, Sendable {
    public var lessonID: String
    /// The saved step to resume at; nil opens the lesson's cover.
    public var step: Int?

    public init(lessonID: String, step: Int?) {
        self.lessonID = lessonID
        self.step = step
    }
}
