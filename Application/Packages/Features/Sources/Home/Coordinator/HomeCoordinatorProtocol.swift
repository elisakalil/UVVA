import Core

@MainActor
public protocol HomeCoordinatorProtocol {
    func openCourse(_ id: String)
    func openLesson(_ suggestion: HomeLessonSuggestion)
    func openLearn(_ kind: CourseKind)
    /// The `+` (HOME-R03): the Cellar's new note (CELLAR-R14).
    func scan()
    /// Opens the Cellar's new note with the wine already loaded (CELLAR-R14a), and the verdict it was rated with
    /// before, if any, so the note asks whether to rate it again. `fromHero`: once saved, the Home goes back to its
    /// top (HOME-R10c).
    func openCellarNote(for wine: Wine, ratedVerdict: Verdict?, fromHero: Bool)
    /// The friends card with two or more friends (HOME-R11, FRI-R20): the Friends tab, choosing who comes.
    func openFriends()
    /// The match card (HOME-R11): a table with the closest friend (FRI-R13).
    func openFriendTable(_ id: String)
    /// A new-friend notification (HOME-R04b): only that friend's profile, with no table set (FRI-R10).
    func openFriend(_ id: String)
    /// The Home added a wine directly to the Cellar.
    func wineAddedToCellar(_ wineKey: String)
    /// The "axis that changed" card (HOME-R17): You › Map, at "Over time" (YOU-R03).
    func openMapHistory()
    /// A friend request notification (HOME-R04b): the Friends tab, where requests are answered (FRI-R08a).
    func openFriendRequests()
    /// A wine-received notification (HOME-R04b): the wine, full screen over the Friends tab (FRI-R11c).
    func openReceivedWine(_ id: String)
}

extension HomeCoordinatorProtocol {
    public func openFriendRequests() {}
    public func openReceivedWine(_ id: String) {}
    public func openLesson(_ suggestion: HomeLessonSuggestion) { openCourse(suggestion.course.id) }
    public func scan() {}
    public func openCellarNote(for wine: Wine, ratedVerdict: Verdict?, fromHero: Bool) {}
    public func openFriends() {}
    public func openFriendTable(_ id: String) {}
    public func openFriend(_ id: String) {}
    public func wineAddedToCellar(_ wineKey: String) {}
    public func openMapHistory() {}
}
