import Foundation

/// One line of "Your readings" (QUIZ-R16).
struct QuizReadingRowUIModel: Equatable, Identifiable {
    var name: String
    /// Filled pips, 0...9.
    var level: Int
    var word: String
    var isStrong: Bool
    var id: String { name }
}
