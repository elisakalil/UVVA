import Foundation

/// A lesson with its steps, read when the player opens it (LESSON-R08, R09).
public struct Lesson: Identifiable, Equatable, Sendable {
    public var summary: LessonSummary
    public var steps: [LessonStep]

    public init(summary: LessonSummary, steps: [LessonStep]) {
        self.summary = summary
        self.steps = steps
    }

    public var id: String { summary.id }
}
