import Core

@MainActor
public protocol HomeCoordinatorProtocol {
    func openCourse(_ id: String)
    func openLesson(_ suggestion: HomeLessonSuggestion)
    func openLearn(_ kind: CourseKind)
    /// The `+` (HOME-R03): the Cellar's new note (CELLAR-R14).
    func scan()
    /// Opens the Cellar's new note with the wine already loaded (CELLAR-R14a).
    func openCellarNote(for wine: Wine, verdict: Verdict?, asksTasting: Bool)
    /// The friends card with two or more friends (HOME-R11, FRI-R20): the Friends tab, choosing who comes.
    func openFriends()
    /// The match card, with one friend (HOME-R11): the last table (FRI-R17).
    func openLastTable()
    /// The "axis that changed" card (HOME-R17): You › Map, at "Over time" (YOU-R03).
    func openMapHistory()
}

extension HomeCoordinatorProtocol {
    public func openLesson(_ suggestion: HomeLessonSuggestion) { openCourse(suggestion.course.id) }
    public func scan() {}
    public func openCellarNote(for wine: Wine, verdict: Verdict?, asksTasting: Bool) {}
    public func openFriends() {}
    public func openLastTable() {}
    public func openMapHistory() {}
}
