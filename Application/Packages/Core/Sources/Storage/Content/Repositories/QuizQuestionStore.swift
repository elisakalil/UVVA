import Core
import Foundation
import SwiftData

/// `QuizQuestionRepository` on the Content store.
public actor QuizQuestionStore: StoreActor, QuizQuestionRepository {
    public nonisolated let executor: StoreExecutor

    public init(modelContainer: ModelContainer) {
        executor = StoreExecutor(modelContainer, label: "app.uvva.store.quiz-questions")
    }

    public func questions() throws -> [QuizQuestion] {
        let descriptor = FetchDescriptor<QuizQuestionEntity>(sortBy: [SortDescriptor(\.axis), SortDescriptor(\.version)])
        return try modelContext.fetch(descriptor).compactMap { entity in
            guard let axis = PalateAxis(rawValue: entity.axis) else { return nil }
            return QuizQuestion(axis: axis, version: entity.version, prompt: entity.prompt, answers: entity.answers)
        }
    }
}
