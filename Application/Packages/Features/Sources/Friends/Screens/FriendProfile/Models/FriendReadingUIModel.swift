import Foundation

/// An axis of the friend's map (FRI-R11, as QUIZ-R16).
struct FriendReadingUIModel: Identifiable, Equatable {
    var id: String { name }
    var name: String
    var level: Int
    var word: String
    var isStrong: Bool
}
