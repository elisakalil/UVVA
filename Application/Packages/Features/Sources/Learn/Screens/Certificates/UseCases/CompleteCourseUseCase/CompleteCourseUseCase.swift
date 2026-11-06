import Core
import Foundation

@MainActor
struct CompleteCourseUseCase: CompleteCourseUseCaseProtocol {
    let learning: any LearningRepository
    let now: () -> Date

    func execute(_ course: Course, previous: LearnContentModel) async -> CourseCompletionResultModel {
        let snapshot = try? await learning.snapshot(for: [course])
        let progress = snapshot?.lessons ?? previous.progress
        let modules = snapshot?.modules ?? previous.modules
        guard CourseRules.state(of: course, module: modules[course.id]) == .done,
              !previous.certificates.contains(where: { $0.courseID == course.id }) else {
            return CourseCompletionResultModel(progress: progress, certificates: previous.certificates, earned: nil, modules: modules)
        }
        let certificate = Certificate(courseID: course.id, date: now())
        do {
            try await learning.addCertificate(certificate)
        } catch {
            return CourseCompletionResultModel(progress: progress, certificates: previous.certificates, earned: nil, modules: modules)
        }
        let certificates = (try? await learning.certificates()) ?? previous.certificates + [certificate]
        return CourseCompletionResultModel(progress: progress, certificates: certificates, earned: certificate, modules: modules)
    }
}
