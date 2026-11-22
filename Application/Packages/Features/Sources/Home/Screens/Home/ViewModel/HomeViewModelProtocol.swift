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
    /// The match card (HOME-R11): a table with that friend.
    func openFriendTable(_ id: String)
    /// The "axis that changed" card (HOME-R17).
    func openMapHistory()
    /// Saves a wine to the Cellar as Not yet.
    func addToCellar(_ wine: Wine) async
    /// "Add to cellar" on the Hero or the wine sheet: the Cellar's new note, which asks about the wine (CELLAR-R14a).
    /// From the Hero, the Home goes back to its top once the note is saved (HOME-R10c).
    func openCellarNote(for wine: Wine, fromHero: Bool)
    /// The wine sheet opens: the Cellar's verdicts, for its grape and region lines.
    func loadTasteHistory() async
    /// HOME-R04: reads again what friends sent, when the Home comes back or the bell is tapped.
    func refreshNotifications() async
    /// HOME-R04, R04b: a tapped notification is read, and leads to what it is about.
    func openNotification(_ notification: AppNotification) async
}

extension HomeViewModelProtocol {
    public func refreshNotifications() async {}
    public func loadTasteHistory() async {}
    public func openNotification(_ notification: AppNotification) async {}
    public func openLesson(_ suggestion: HomeLessonSuggestion) { openCourse(suggestion.course.id) }
    public func openCellarNote(for wine: Wine, fromHero: Bool) {}
}
