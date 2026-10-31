import Foundation

/// Reads the Quiz questions (Content store).
public protocol QuizQuestionRepository: Sendable {
    func questions() async throws -> [QuizQuestion]
}
