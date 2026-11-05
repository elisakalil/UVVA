#if DEBUG
import Combine
import Core
import Foundation

@MainActor
final class MockLearnViewModel: LearnViewModelProtocol {
    @Published var uiModel = LearnUIModel()
    var player: MockLessonPlayerViewModel?
    func load() async {}
    func updateQuery(_ query: String) { uiModel.query = query }
    func show(_ kind: CourseKind) { uiModel.tab = kind }
    func toggle(_ courseID: String) {}
    func selectCountry(_ name: String) {}
    func selectRegion(_ courseID: String) {}
    func selectGrapeFilter(id: String) {}
    func selectPathLevel(_ level: String?) {}
    func openResult(_ result: SearchResultUIModel) async {}
    func startCourse(id: String) async {}
    func showCertificate(courseID: String) async {}
    func closeCertificate() {}
}

@MainActor
final class MockLessonPlayerViewModel: LessonPlayerViewModelProtocol {
    let id = UUID()
    @Published var uiModel = LessonPlayerUIModel()
    func back() {}
    func close() {}
    func begin() {}
    func primary() {}
    func reviewPrevious() {}
    func closeCertificate() {}
    func tapOption(_ option: Int) {}
    func tapWord(_ word: String) {}
    func tapRow(_ position: Int) {}
    func tapLeft(_ pair: Int) {}
    func tapRight(_ pair: Int) {}
}
#endif
