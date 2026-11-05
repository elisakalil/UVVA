@MainActor
protocol LoadQuizQuestionsUseCaseProtocol {
    func execute() async throws -> QuizQuestionBank
}
