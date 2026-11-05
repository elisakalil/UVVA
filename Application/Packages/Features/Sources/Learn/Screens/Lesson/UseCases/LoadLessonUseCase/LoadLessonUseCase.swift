import Core
import Foundation

@MainActor
struct LoadLessonUseCase: LoadLessonUseCaseProtocol {
    let catalog: any CourseCatalog

    func execute(id: String) async -> Lesson? { try? await catalog.lesson(id: id) }
}
