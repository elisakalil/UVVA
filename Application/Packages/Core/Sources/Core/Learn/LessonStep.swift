import Foundation

/// One step of a lesson (LESSON.md §6). Ordering items are kept in the right order; the player shuffles them.
public enum LessonStep: Equatable, Sendable {
    case concept(title: String, body: String, highlight: String?)
    case tip(body: String)
    case multipleChoice(prompt: String, options: [String], answer: Int, explanation: String)
    case selectMultiple(prompt: String, options: [String], answers: Set<Int>, explanation: String)
    case trueFalse(prompt: String, answer: Bool, explanation: String)
    case fillBlank(prompt: String, options: [String], answer: String, explanation: String)
    case ordering(prompt: String, items: [String], explanation: String)
    case matchPairs(prompt: String, pairs: [MatchPair], explanation: String?)
    case summary(title: String, points: [String])

    /// Steps the learner answers; they count in the Summary score (LEARN-R19).
    public var isQuestion: Bool {
        switch self {
        case .concept, .tip, .summary: false
        default: true
        }
    }
}
