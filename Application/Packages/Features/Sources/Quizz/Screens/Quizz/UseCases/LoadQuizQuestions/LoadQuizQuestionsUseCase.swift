import Core
import Foundation

@MainActor
struct LoadQuizQuestionsUseCase: LoadQuizQuestionsUseCaseProtocol {
    let questions: any QuizQuestionRepository

    func execute() async throws -> QuizQuestionBank {
        let bank = QuizQuestionBank(try await questions.questions())
        guard bank.isComplete else { throw PreparationError.incompleteQuestions }
        try Task.checkCancellation()
        return bank
    }

    private enum PreparationError: LocalizedError {
        case incompleteQuestions
        var errorDescription: String? { "The quiz questions could not be loaded." }
    }
}
