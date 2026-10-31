import Foundation

/// How the Quiz was opened (QUIZ-R24).
public enum QuizEntry: Sendable {
    /// End of the sign-up, or a session without a map.
    case firstMap
    /// You › Map › "Redo the map".
    case redo
}
