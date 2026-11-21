import Foundation

/// An axis in the Compatibility tab's "Reading by reading" (FRI-R12): both readings, and how far apart.
struct FriendCompareRowUIModel: Identifiable, Equatable {
    var id: String { name }
    var name: String
    /// "Same", "Close", "Apart", "Opposed".
    var verdict: String
    /// Both 0...9, as the pips of the Map's readings (QUIZ-R16).
    var mineLevel: Int
    var theirsLevel: Int
    var isSame: Bool
}
