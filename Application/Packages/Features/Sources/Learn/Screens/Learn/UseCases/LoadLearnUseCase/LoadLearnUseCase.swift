import Core
import Foundation

@MainActor
struct LoadLearnUseCase: LoadLearnUseCaseProtocol {
    let catalog: any CourseCatalog
    let learning: any LearningRepository
    let profiles: any ProfileRepository

    func execute(previous: LearnContent) async -> LearnContent {
        var result = previous
        for kind in CourseKind.allCases {
            result.courses[kind] = (try? await catalog.courses(kind)) ?? previous.courses[kind] ?? []
        }
        result.progress = (try? await learning.progress()) ?? previous.progress
        result.certificates = (try? await learning.certificates()) ?? previous.certificates
        result.firstName = ((try? await profiles.currentProfile()) ?? nil)?.firstName ?? previous.firstName
        return result
    }
}
