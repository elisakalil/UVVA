import Foundation

/// Progress (YOU-R04 to R07).
public struct ProgressUIModel: Equatable {
    var stats: [ProgressStat]
    var specialist: String
    var suggestionEyebrow: String
    var suggestionTitle: String
    var suggestionNote: String
    var suggestionReason: String?
    var suggestedCourseID: String?
    var cta: String?
    var specialistInText = String(localized: "Specialist in", bundle: .module)
}
