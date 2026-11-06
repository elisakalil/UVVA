import Core
import Foundation

@MainActor
struct LoadLearnUseCase: LoadLearnUseCaseProtocol {
    let catalog: any CourseCatalog
    let learning: any LearningRepository
    let profiles: any ProfileRepository

    func execute(previous: LearnContentModel) async -> LearnContentModel {
        var result = previous
        for kind in CourseKind.allCases {
            result.courses[kind] = (try? await catalog.courses(kind)) ?? previous.courses[kind] ?? []
        }
        let courses = Array(result.courses.values.joined())
        if let snapshot = try? await learning.snapshot(for: courses) {
            result.progress = snapshot.lessons
            result.modules = snapshot.modules
        }
        result.certificates = (try? await learning.certificates()) ?? previous.certificates
        result.firstName = ((try? await profiles.currentProfile()) ?? nil)?.firstName ?? previous.firstName
        return result
    }
}
