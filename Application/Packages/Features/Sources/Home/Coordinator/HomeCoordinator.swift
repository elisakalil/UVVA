import Core

/// Bridges Home navigation requests to the application, without importing other features.
@MainActor
public struct HomeCoordinator: HomeCoordinatorProtocol {
    private let onOpenLesson: ((HomeLessonSuggestion) -> Void)?
    private let onOpenCourse: (String) -> Void
    private let onOpenLearn: (CourseKind) -> Void
    private let onScan: () -> Void
    private let onOpenCellarNote: (Wine, Verdict?, _ fromHero: Bool) -> Void
    private let onOpenFriends: () -> Void
    private let onOpenFriendTable: (String) -> Void
    private let onOpenFriend: (String) -> Void
    private let onWineAddedToCellar: (String) -> Void
    private let onOpenMapHistory: () -> Void
    private let onOpenFriendRequests: () -> Void
    private let onOpenReceivedWine: (String) -> Void

    public init(onOpenCourse: @escaping (String) -> Void,
                onOpenLearn: @escaping (CourseKind) -> Void,
                onOpenLesson: ((HomeLessonSuggestion) -> Void)? = nil,
                onScan: @escaping () -> Void = {},
                onOpenCellarNote: @escaping (Wine, Verdict?, _ fromHero: Bool) -> Void = { _, _, _ in },
                onOpenFriends: @escaping () -> Void = {},
                onOpenFriendTable: @escaping (String) -> Void = { _ in },
                onOpenFriend: @escaping (String) -> Void = { _ in },
                onOpenMapHistory: @escaping () -> Void = {},
                onOpenFriendRequests: @escaping () -> Void = {},
                onOpenReceivedWine: @escaping (String) -> Void = { _ in },
                onWineAddedToCellar: @escaping (String) -> Void = { _ in }) {
        self.onOpenFriendRequests = onOpenFriendRequests
        self.onOpenReceivedWine = onOpenReceivedWine
        self.onOpenFriendTable = onOpenFriendTable
        self.onOpenFriend = onOpenFriend
        self.onWineAddedToCellar = onWineAddedToCellar
        self.onOpenMapHistory = onOpenMapHistory
        self.onScan = onScan
        self.onOpenCellarNote = onOpenCellarNote
        self.onOpenFriends = onOpenFriends
        self.onOpenLesson = onOpenLesson
        self.onOpenCourse = onOpenCourse
        self.onOpenLearn = onOpenLearn
    }

    public func openLesson(_ suggestion: HomeLessonSuggestion) {
        if let onOpenLesson { onOpenLesson(suggestion) }
        else { onOpenCourse(suggestion.course.id) }
    }
    public func openCourse(_ id: String) { onOpenCourse(id) }
    public func openLearn(_ kind: CourseKind) { onOpenLearn(kind) }
    public func scan() { onScan() }
    public func openCellarNote(for wine: Wine, ratedVerdict: Verdict?, fromHero: Bool) {
        onOpenCellarNote(wine, ratedVerdict, fromHero)
    }
    public func openFriends() { onOpenFriends() }
    public func openFriendTable(_ id: String) { onOpenFriendTable(id) }
    public func openFriend(_ id: String) { onOpenFriend(id) }
    public func wineAddedToCellar(_ wineKey: String) { onWineAddedToCellar(wineKey) }
    public func openMapHistory() { onOpenMapHistory() }
    public func openFriendRequests() { onOpenFriendRequests() }
    public func openReceivedWine(_ id: String) { onOpenReceivedWine(id) }
}
