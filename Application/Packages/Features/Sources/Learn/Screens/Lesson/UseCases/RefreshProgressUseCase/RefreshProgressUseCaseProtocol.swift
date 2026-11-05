import Core
import Foundation

@MainActor
protocol RefreshProgressUseCaseProtocol {
    func execute(previous: [String: LessonProgress]) async -> [String: LessonProgress]
}
