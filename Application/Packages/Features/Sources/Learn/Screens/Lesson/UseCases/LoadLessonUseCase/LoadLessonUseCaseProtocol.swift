import Core
import Foundation

@MainActor
protocol LoadLessonUseCaseProtocol {
    func execute(id: String) async -> Lesson?
}
