import Foundation

/// A lesson as its course lists it: everything but the steps (LESSON-R08).
public struct LessonSummary: Identifiable, Equatable, Sendable {
    public var id: String
    public var courseID: String
    public var order: Int
    public var title: String
    public var subtitle: String
    public var xp: Int
    public var minutes: Int
    public var isReview: Bool
    public var objectives: [String]

    public init(id: String, courseID: String, order: Int, title: String, subtitle: String, xp: Int, minutes: Int,
                isReview: Bool, objectives: [String]) {
        self.id = id
        self.courseID = courseID
        self.order = order
        self.title = title
        self.subtitle = subtitle
        self.xp = xp
        self.minutes = minutes
        self.isReview = isReview
        self.objectives = objectives
    }
}
