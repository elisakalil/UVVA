import Foundation

/// Where the learner is in one lesson (SHARED-R15, R17; ARCHITECTURE §2.1 `LessonProgress`).
/// Persisted on departure, including a departure from the cover.
public struct LessonProgress: Equatable, Sendable {
    public var lessonID: String
    public var courseID: String
    /// Monotonic within a lesson session; rejects delayed writes from earlier snapshots.
    public var revision: Int
    /// The saved screen: -1 is the cover; steps start at 0.
    public var currentStep: Int
    /// The checked answers, by step index.
    public var answers: [Int: LessonAnswer]
    /// Set once, the first time the Summary is reached (LEARN-R19a).
    public var completedAt: Date?
    public var lastOpenedAt: Date
    /// Earned on the first completion only (LEARN-R21).
    public var xp: Int

    public init(lessonID: String, courseID: String, currentStep: Int = 0, answers: [Int: LessonAnswer] = [:],
                completedAt: Date? = nil, lastOpenedAt: Date, xp: Int = 0, revision: Int = 0) {
        self.revision = revision
        self.lessonID = lessonID
        self.courseID = courseID
        self.currentStep = currentStep
        self.answers = answers
        self.completedAt = completedAt
        self.lastOpenedAt = lastOpenedAt
        self.xp = xp
    }

    public var isCompleted: Bool { completedAt != nil }
}
