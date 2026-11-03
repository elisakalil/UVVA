import Foundation

/// The Summary (LEARN-R19).
struct LessonSummaryUIModel: Equatable {
    var toast: String
    /// "means “cheers” in French"
    var toastMeaning: String
    /// The note shown over the Summary: "Lesson complete +15 XP", without XP when the lesson gave it before (LEARN-R19a).
    var completion: String
    var points: [String]
    /// "Next lesson" or "Module complete".
    var nextEyebrow: String
    var nextTitle: String
}
