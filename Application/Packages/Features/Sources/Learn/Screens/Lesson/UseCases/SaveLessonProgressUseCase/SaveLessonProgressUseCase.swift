import Core
import Foundation

@MainActor
struct SaveLessonProgressUseCase: SaveLessonProgressUseCaseProtocol {
    let learning: any LearningRepository

    func execute(_ progress: LessonProgress) async throws { try await learning.save(progress) }
}
