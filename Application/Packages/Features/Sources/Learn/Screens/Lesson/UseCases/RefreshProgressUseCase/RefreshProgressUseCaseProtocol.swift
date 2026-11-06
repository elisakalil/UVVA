import Core
import Foundation

@MainActor
protocol RefreshProgressUseCaseProtocol {
    func execute(_ courses: [Course]) async throws -> LearningSnapshot
}
