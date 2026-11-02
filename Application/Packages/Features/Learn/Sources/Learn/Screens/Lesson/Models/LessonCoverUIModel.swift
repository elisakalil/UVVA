import Foundation

/// The cover of a lesson (LEARN-R12).
struct LessonCoverUIModel: Equatable {
    /// The course title.
    var eyebrow: String
    /// "03"
    var number: String
    var title: String
    var subtitle: String
    var minutes: String
    var xp: String
    var steps: String
    var objectives: [String]
    /// From lesson 2 on.
    var showsReviewPrevious: Bool
}
