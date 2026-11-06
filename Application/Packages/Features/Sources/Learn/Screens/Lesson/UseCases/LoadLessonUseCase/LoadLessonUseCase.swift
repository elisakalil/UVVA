import Core
import Foundation

@MainActor
struct LoadLessonUseCase: LoadLessonUseCaseProtocol {
    let catalog: any CourseCatalog

    func execute(id: String) async -> Lesson? { await Task.detached(priority: .userInitiated) { try? await catalog.lesson(id: id) }.value }
}
