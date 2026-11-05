import Core
import Foundation

@MainActor
protocol SaveLessonProgressUseCaseProtocol {
    func execute(_ progress: LessonProgress) async throws
}
