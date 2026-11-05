import Core
import Foundation

@MainActor
struct RefreshProgressUseCase: RefreshProgressUseCaseProtocol {
    let learning: any LearningRepository

    func execute(previous: [String: LessonProgress]) async -> [String: LessonProgress] {
        (try? await learning.progress()) ?? previous
    }
}
