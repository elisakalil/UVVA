import Foundation

/// What the learner checked on a question step, kept so a lesson resumes with its answers (LEARN-R14).
public enum LessonAnswer: Codable, Equatable, Sendable {
    /// multipleChoice and selectMultiple: the option indexes.
    case options(Set<Int>)
    case trueFalse(Bool)
    case word(String)
    /// ordering: the item indexes in the order the learner left them.
    case order([Int])
    /// matchPairs: every pair linked, after this many wrong tries (LEARN-R18).
    case pairs(misses: Int)
}
