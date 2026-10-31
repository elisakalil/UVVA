import Foundation

/// Where the Quiz is (QUIZZ.md §3).
enum QuizStep: Equatable, Sendable {
    case intro
    /// Index into `QuizFlow.order`, 0...7.
    case reading(Int)
    case result
}
