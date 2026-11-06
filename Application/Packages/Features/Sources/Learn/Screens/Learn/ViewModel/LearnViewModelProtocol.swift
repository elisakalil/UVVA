import Combine
import Core

@MainActor
public protocol LearnViewModelProtocol: ObservableObject {
    associatedtype PlayerModel: LessonPlayerViewModelProtocol
    var uiModel: LearnUIModel { get }
    var player: PlayerModel? { get }
    var lessonLoadingPublisher: AnyPublisher<Bool, Never> { get }
    func saveLessonOnBackground() async
    func retryLesson() async
    func cancelLessonLoading()
    func load() async
    func updateQuery(_ query: String)
    func show(_ kind: CourseKind)
    func toggle(_ courseID: String)
    func selectCountry(_ name: String)
    func selectRegion(_ courseID: String)
    func selectGrapeFilter(id: String)
    func selectPathLevel(_ level: String?)
    func openResult(_ result: SearchResultUIModel) async
    func startCourse(id: String) async
    func showCertificate(courseID: String) async
    func closeCertificate()
}

public extension LearnViewModelProtocol {
    var lessonLoadingPublisher: AnyPublisher<Bool, Never> { Just(false).eraseToAnyPublisher() }
    func saveLessonOnBackground() async {}
    func retryLesson() async {}
    func cancelLessonLoading() {}
}
