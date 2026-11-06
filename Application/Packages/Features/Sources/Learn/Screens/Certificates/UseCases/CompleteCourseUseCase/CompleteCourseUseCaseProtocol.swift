import Core
import Foundation

@MainActor
protocol CompleteCourseUseCaseProtocol {
    func execute(_ course: Course, previous: LearnContentModel) async -> CourseCompletionResultModel
}
