import Core
import Foundation

protocol SaveLessonProgressUseCaseProtocol: Sendable {
    func execute(_ progress: LessonProgress, in course: Course) async throws
}
