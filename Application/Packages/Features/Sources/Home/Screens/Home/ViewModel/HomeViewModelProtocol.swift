import Combine
import Core

@MainActor
public protocol HomeViewModelProtocol: ObservableObject {
    var uiModel: HomeUIModel { get }
    func loadIfNeeded() async
    func openCourse(_ id: String)
    func openLesson(_ suggestion: HomeLessonSuggestion)
    func openLearn(_ kind: CourseKind)
    /// The `+` (HOME-R03).
    func scan()
    /// The friends card with friends (HOME-R11).
    func openFriends()
    /// The match card (HOME-R11).
    func openLastTable()
    /// Saves the wine to the Cellar as Not yet (CELLAR-R13c, HOME-R28).
    func addToCellar(_ wine: Wine) async
    /// "Would you drink it again?" (HOME-R24): moves the map and tells which axes moved; with `addToCellar`, the wine
    /// goes to the Cellar as Tasted with the verdict.
    func rate(_ wine: Wine, verdict: Verdict, addToCellar: Bool) async
}

extension HomeViewModelProtocol {
    public func openLesson(_ suggestion: HomeLessonSuggestion) { openCourse(suggestion.course.id) }
}
