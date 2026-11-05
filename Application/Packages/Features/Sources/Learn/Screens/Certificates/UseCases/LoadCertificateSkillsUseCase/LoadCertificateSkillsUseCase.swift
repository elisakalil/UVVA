import Core
import Foundation

@MainActor
struct LoadCertificateSkillsUseCase: LoadCertificateSkillsUseCaseProtocol {
    let catalog: any CourseCatalog

    func execute(_ course: Course) async -> [String] {
        guard let review = course.lessons.last(where: \.isReview) ?? course.lessons.last,
              let lesson = try? await catalog.lesson(id: review.id) else { return [] }
        var skills: [String] = []
        for case let .summary(_, points) in lesson.steps { skills = points }
        return skills.isEmpty ? review.objectives : skills
    }
}
