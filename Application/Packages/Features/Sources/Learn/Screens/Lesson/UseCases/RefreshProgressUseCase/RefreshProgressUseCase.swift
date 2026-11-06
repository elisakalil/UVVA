import Core
import Foundation

@MainActor
struct RefreshProgressUseCase: RefreshProgressUseCaseProtocol {
    let learning: any LearningRepository

    func execute(_ courses: [Course]) async throws -> LearningSnapshot {
        try await Task.detached(priority: .userInitiated) { try await learning.snapshot(for: courses) }.value
    }
}
