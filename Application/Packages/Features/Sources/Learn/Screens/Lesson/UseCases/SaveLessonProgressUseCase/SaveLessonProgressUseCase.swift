import Core
import Foundation

struct SaveLessonProgressUseCase: SaveLessonProgressUseCaseProtocol {
    let learning: any LearningRepository

    func execute(_ progress: LessonProgress, in course: Course) async throws { try await learning.save(progress, in: course) }
}
