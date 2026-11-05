import Core
import Foundation
import Testing
@testable import Quizz

private struct EmptyQuestions: QuizQuestionRepository {
    func questions() async throws -> [QuizQuestion] { [] }
}

@MainActor
private final class RetryMapSave: SaveQuizMapUseCaseProtocol {
    private(set) var attempts = 0
    func execute(_ map: PalateMap) async throws {
        attempts += 1
        if attempts == 1 { throw CocoaError(.fileWriteUnknown) }
    }
}

@MainActor
struct QuizPreparationTests {
    @Test func incompleteQuestions_areRejectedWithoutPublishingABank() async {
        let model = QuizFactory(questions: EmptyQuestions(), maps: PalateMapRepositorySpy())
            .makeViewModel(entry: .firstMap, firstName: nil,
                           coordinator: QuizCoordinator(entry: .firstMap, onExit: { _ in }))
        do {
            try await model.prepare()
            Issue.record("Expected incomplete questions to be rejected")
        } catch {
            #expect(model.bank == nil)
        }
    }

    @Test func retryAfterSaveFailure_clearsErrorAndOpensSharing() async throws {
        let save = RetryMapSave()
        let model = QuizViewModel(entry: .firstMap, firstName: nil,
                                   loadQuestionsUseCase: LoadQuizQuestionsUseCase(questions: QuestionRepositoryStub()),
                                   saveMapUseCase: save,
                                   coordinator: QuizCoordinator(entry: .firstMap, onExit: { _ in }))
        try await model.prepare()
        model.start()
        for _ in 0..<8 { model.select(4); model.next() }
        await model.keep()
        #expect(model.uiModel.failedToSave)
        #expect(!model.uiModel.isSaving)
        #expect(!model.uiModel.isSharing)
        await model.keep()
        #expect(!model.uiModel.failedToSave)
        #expect(!model.uiModel.isSaving)
        #expect(model.uiModel.isSharing)
        #expect(save.attempts == 2)
    }
}
