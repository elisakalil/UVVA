import Combine
import Core

@MainActor
public protocol HomeViewModelProtocol: ObservableObject {
    var uiModel: HomeUIModel { get }
    func loadIfNeeded() async
    func openCourse(_ id: String)
    func openLesson(_ suggestion: HomeLessonSuggestion)
    func openLearn(_ kind: CourseKind)
}

extension HomeViewModelProtocol {
    public func openLesson(_ suggestion: HomeLessonSuggestion) { openCourse(suggestion.course.id) }
}
