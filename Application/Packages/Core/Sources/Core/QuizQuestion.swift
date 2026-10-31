import Foundation

/// One version of the question for an axis, with a word for each position of the bar (QUIZ-R08).
public struct QuizQuestion: Equatable, Sendable {
    public var axis: PalateAxis
    /// 1...3
    public var version: Int
    public var prompt: String
    /// Ten answers, one per position 0...9.
    public var answers: [String]

    public init(axis: PalateAxis, version: Int, prompt: String, answers: [String]) {
        self.axis = axis
        self.version = version
        self.prompt = prompt
        self.answers = answers
    }
}
