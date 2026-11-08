import Core

@MainActor
public protocol HomeCoordinatorProtocol {
    func openCourse(_ id: String)
    func openLesson(_ suggestion: HomeLessonSuggestion)
    func openLearn(_ kind: CourseKind)
    /// The `+` (HOME-R03): the Cellar's new note (CELLAR-R14).
    func scan()
    /// The friends card with two or more friends (HOME-R11, FRI-R20): the Friends tab, choosing who comes.
    func openFriends()
    /// The match card, with one friend (HOME-R11): the last table (FRI-R17).
    func openLastTable()
}

extension HomeCoordinatorProtocol {
    public func openLesson(_ suggestion: HomeLessonSuggestion) { openCourse(suggestion.course.id) }
    public func scan() {}
    public func openFriends() {}
    public func openLastTable() {}
}
