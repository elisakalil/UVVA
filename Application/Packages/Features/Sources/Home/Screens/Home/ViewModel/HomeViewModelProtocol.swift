import Combine
import Core

@MainActor
public protocol HomeViewModelProtocol: ObservableObject {
    var uiModel: HomeUIModel { get }
    func loadIfNeeded() async
    func openCourse(_ id: String)
    func openLearn(_ kind: CourseKind)
}
