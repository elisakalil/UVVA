import Foundation

/// Progress (YOU-R04 to R07).
struct ProgressUIModel: Equatable {
    var stats: [ProgressStat]
    var specialist: String
    var suggestionEyebrow: String
    var suggestionTitle: String
    var suggestionNote: String
    var cta: String
}
