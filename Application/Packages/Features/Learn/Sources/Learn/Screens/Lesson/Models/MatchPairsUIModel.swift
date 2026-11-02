import Foundation

struct MatchPairsUIModel: Equatable {
    var prompt: String
    /// Ids are pair indexes on both sides; the right side is shuffled (LEARN-R17b).
    var left: [OptionUIModel]
    var right: [OptionUIModel]
    /// "[n] of [total] matched" or "Not a pair. Try again." (LEARN-R18).
    var status: String
    var isMiss: Bool
}
