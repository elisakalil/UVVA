import Foundation

/// The Summary (LEARN-R19).
struct LessonSummaryUIModel: Equatable {
    var toast: String
    /// "means “health” in French"
    var toastMeaning: String
    var title: String
    /// "+15 XP", or "Reviewed" when the lesson gave its XP before (LEARN-R19a).
    var xp: String
    /// "4/6"
    var score: String
    var missed: [String]
    var points: [String]
    /// "Next lesson" or "Module complete".
    var nextEyebrow: String
    var nextTitle: String
}
