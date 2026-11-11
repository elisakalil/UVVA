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
    /// The "axis that changed" card (HOME-R17).
    func openMapHistory()
    /// Saves a wine to the Cellar as Not yet.
    func addToCellar(_ wine: Wine) async
    /// Opens the Cellar's new note from the Hero or wine sheet. The Hero asks about tasting if there is no verdict.
    func openCellarNote(for wine: Wine, verdict: Verdict?, asksTasting: Bool)
    /// "Would you drink it again?" (HOME-R24): moves the map and tells which axes moved; with `addToCellar`, a wine
    /// already in the Cellar becomes Tasted with the verdict.
    func rate(_ wine: Wine, verdict: Verdict, addToCellar: Bool) async
}

extension HomeViewModelProtocol {
    public func openLesson(_ suggestion: HomeLessonSuggestion) { openCourse(suggestion.course.id) }
    public func openCellarNote(for wine: Wine, verdict: Verdict?, asksTasting: Bool) {}
}
