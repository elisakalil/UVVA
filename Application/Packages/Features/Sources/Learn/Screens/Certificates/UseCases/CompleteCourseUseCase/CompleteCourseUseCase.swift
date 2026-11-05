import Core
import Foundation

@MainActor
struct CompleteCourseUseCase: CompleteCourseUseCaseProtocol {
    let learning: any LearningRepository
    let now: () -> Date

    func execute(_ course: Course, previous: LearnContent) async -> CourseCompletion {
        let progress = (try? await learning.progress()) ?? previous.progress
        guard CourseRules.state(of: course, progress: progress) == .done,
              !previous.certificates.contains(where: { $0.courseID == course.id }) else {
            return CourseCompletion(progress: progress, certificates: previous.certificates, earned: nil)
        }
        let certificate = Certificate(courseID: course.id, date: now())
        do {
            try await learning.addCertificate(certificate)
        } catch {
            return CourseCompletion(progress: progress, certificates: previous.certificates, earned: nil)
        }
        let certificates = (try? await learning.certificates()) ?? previous.certificates + [certificate]
        return CourseCompletion(progress: progress, certificates: certificates, earned: certificate)
    }
}
