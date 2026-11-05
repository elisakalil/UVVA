import Core
import Foundation

@MainActor
protocol CompleteCourseUseCaseProtocol {
    func execute(_ course: Course, previous: LearnContent) async -> CourseCompletion
}
