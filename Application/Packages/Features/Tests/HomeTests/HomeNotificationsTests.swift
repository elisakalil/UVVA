import Core
import Foundation
import Testing
@testable import Home

extension AppNotification {
    static func read(_ id: String) -> AppNotification {
        AppNotification(id: id, kind: .mapMoved(axis: .tannin, delta: 0.1), date: .distantPast, isRead: true)
    }

    static func unread(_ id: String) -> AppNotification {
        AppNotification(id: id, kind: .mapMoved(axis: .tannin, delta: 0.1), date: .distantPast, isRead: false)
    }
}

// MARK: HOME-R04a · O que gera as notificações

struct HomeNotificationsBuilderTests {
    let builder = HomeNotificationsBuilder()
    let now = Date(timeIntervalSince1970: 2_000_000_000)
    let hour: TimeInterval = 3600
    let day: TimeInterval = 24 * 3600

    private func model(friends: [Friend] = [], lastRating: Rating? = nil, courses: [CourseProgress] = []) -> HomeContentModel {
        var model = HomeContentModel.full
        model.friends = friends
        model.lastRating = lastRating
        model.courses = courses
        model.notifications = []
        return model
    }

    private func course(openedAgo: TimeInterval, completed: Int = 1) -> CourseProgress {
        CourseProgress(id: "grape-tannat", title: "Tannat", totalLessons: 6, completedLessons: completed, hasStarted: true,
                       lastOpenedAt: now.addingTimeInterval(-openedAgo), current: LessonRef(number: 2, title: "Soil", step: 1))
    }

    @Test func HOME_R04a_friendRequest_isListed() {
        let sources = HomeNotificationSources(requests: [.init(userID: "rita", name: "Rita", sentAt: now.addingTimeInterval(-hour))])
        let list = builder.build(from: model(), sources: sources, now: now)
        #expect(list.map(\.kind) == [.friendRequest(userID: "rita", name: "Rita")])
        #expect(list.first?.isRead == false)
    }

    @Test func HOME_R04a_newFriend_carriesTheMatch() throws {
        let marina = Friend(id: "marina", name: "Marina", map: HomeContentModel.full.palateMap, addedAt: now.addingTimeInterval(-day))
        let list = builder.build(from: model(friends: [marina]), sources: .init(), now: now)
        let first = try #require(list.first)
        #expect(first.kind == .newFriend(friendID: "marina", name: "Marina", compatibility: 100))
        #expect(first.date == marina.addedAt)
    }

    @Test func HOME_R04a_wineReceived_isListed() {
        let wine = SharedWineRecord(id: "m-u-w", from: "m", fromName: "Marina", to: "u", wineID: "w", wineName: "Mencía",
                                    sentAt: now.addingTimeInterval(-2 * hour), snapshot: nil)
        let list = builder.build(from: model(), sources: .init(wines: [wine]), now: now)
        #expect(list.map(\.kind) == [.wineReceived(id: "m-u-w", from: "Marina", wine: "Mencía")])
    }

    @Test func HOME_R04a_mapMoved_followsTheLastRating() {
        let rating = Rating(wineKey: "pontoforte", verdict: .yes, date: now.addingTimeInterval(-hour),
                            deltas: [.tannin: 0.4, .fruit: -0.1])
        let list = builder.build(from: model(lastRating: rating), sources: .init(), now: now)
        #expect(list.map(\.kind) == [.mapMoved(axis: .tannin, delta: 0.4)])
    }

    @Test func HOME_R04a_ratingThatMovedNothing_isNotListed() {
        let rating = Rating(wineKey: "pontoforte", verdict: .maybe, date: now, deltas: [:])
        #expect(builder.build(from: model(lastRating: rating), sources: .init(), now: now).isEmpty)
    }

    @Test func HOME_R04a_lessonLeftADay_isWaiting() {
        let list = builder.build(from: model(courses: [course(openedAgo: 2 * day)]), sources: .init(), now: now)
        #expect(list.map(\.kind) == [.lessonWaiting(courseID: "grape-tannat", course: "Tannat", lesson: 2)])
    }

    @Test func HOME_R04a_severalCoursesStarted_onlyTheLastOpenedIsWaiting() {
        var older = course(openedAgo: 5 * day)
        older.id = "region-douro"
        older.title = "Douro"
        let list = builder.build(from: model(courses: [older, course(openedAgo: 2 * day)]), sources: .init(), now: now)
        #expect(list.map(\.kind) == [.lessonWaiting(courseID: "grape-tannat", course: "Tannat", lesson: 2)])
    }

    @Test func HOME_R04a_lessonOpenedToday_isNotWaiting() {
        #expect(builder.build(from: model(courses: [course(openedAgo: hour)]), sources: .init(), now: now).isEmpty)
    }

    @Test func HOME_R04a_finishedCourse_isNotWaiting() {
        let done = course(openedAgo: 2 * day, completed: 6)
        #expect(builder.build(from: model(courses: [done]), sources: .init(), now: now).isEmpty)
    }

    @Test func HOME_R04a_olderThan30Days_isLeftOut() {
        let old = Friend(id: "tomas", name: "Tomás", map: HomeContentModel.full.palateMap, addedAt: now.addingTimeInterval(-31 * day))
        #expect(builder.build(from: model(friends: [old]), sources: .init(), now: now).isEmpty)
    }

    @Test func HOME_R04a_newestFirst() {
        let sources = HomeNotificationSources(requests: [
            .init(userID: "a", name: "A", sentAt: now.addingTimeInterval(-3 * day)),
            .init(userID: "b", name: "B", sentAt: now.addingTimeInterval(-hour))
        ])
        let list = builder.build(from: model(), sources: sources, now: now)
        #expect(list.map(\.date) == [now.addingTimeInterval(-hour), now.addingTimeInterval(-3 * day)])
    }

    @Test func HOME_R04_readIDs_stayRead() throws {
        let request = HomeNotificationSources.Request(userID: "rita", name: "Rita", sentAt: now.addingTimeInterval(-hour))
        let first = try #require(builder.build(from: model(), sources: .init(requests: [request]), now: now).first)
        let again = builder.build(from: model(), sources: .init(requests: [request], read: [first.id]), now: now)
        #expect(again.map(\.isRead) == [true])
    }
}

// MARK: HOME-R04 · Sino, ao abrir uma notificação

@MainActor
private final class NotificationsSpy: LoadNotificationsUseCaseProtocol {
    var sourcesToReturn = HomeNotificationSources()
    var marked: [String] = []
    func sources() async -> HomeNotificationSources { sourcesToReturn }
    func markRead(_ id: String) async { marked.append(id) }
}

private struct FixedHomeLoader: LoadHomeUseCaseProtocol {
    var model: HomeContentModel
    func execute() async throws -> HomeLoadResultModel { HomeLoadResultModel(model: model, inviteLink: nil) }
}

private struct NoCellarAction: AddWineToCellarUseCaseProtocol {
    func execute(_ wine: Wine) async throws {}
}

@MainActor
struct HomeNotificationsViewModelTests {
    let now = Date(timeIntervalSince1970: 2_000_000_000)

    private func makeHome(requests: [String], friends: [Friend] = [], opened: @escaping (String) -> Void = { _ in })
        -> (HomeViewModel, NotificationsSpy) {
        var model = HomeContentModel.full
        model.friends = friends
        model.lastRating = nil
        model.courses = []
        let spy = NotificationsSpy()
        spy.sourcesToReturn = HomeNotificationSources(requests: requests.enumerated().map { index, id in
            .init(userID: id, name: id, sentAt: now.addingTimeInterval(-Double(index + 1) * 60))
        })
        let home = HomeViewModel(
            loadHomeUseCase: FixedHomeLoader(model: model), loadPalateStateUseCase: PalateStateStub(),
            rankWinesUseCase: WineRankingSpy(), addWineToCellarUseCase: NoCellarAction(),
            loadNotificationsUseCase: spy,
            coordinator: HomeCoordinator(onOpenCourse: { _ in }, onOpenLearn: { _ in },
                                         onOpenFriendTable: { opened("table-\($0)") },
                                         onOpenFriend: { opened("friend-\($0)") },
                                         onOpenFriendRequests: { opened("requests") }),
            now: { [now] in now }, calendar: .current)
        return (home, spy)
    }

    private func hasDot(_ home: HomeViewModel) -> Bool {
        guard case let .header(_, hasUnread) = home.uiModel.content?.cards.first else { return false }
        return hasUnread
    }

    @Test func HOME_R04_noUnread_noDot() async throws {
        let (home, _) = makeHome(requests: [])
        try await home.prepare()
        await home.refreshNotifications()
        #expect(!hasDot(home))
    }

    @Test func HOME_R04_twoUnread_openingOne_dotStays() async throws {
        let (home, spy) = makeHome(requests: ["rita", "tomas"])
        try await home.prepare()
        await home.refreshNotifications()
        #expect(hasDot(home))

        let first = try #require(home.uiModel.notifications.first)
        await home.openNotification(first)
        #expect(spy.marked == [first.id])
        #expect(home.uiModel.notifications.filter { !$0.isRead }.count == 1)
        #expect(hasDot(home))
    }

    @Test func HOME_R04_lastUnreadOpened_dotGoes() async throws {
        var opened: [String] = []
        let (home, _) = makeHome(requests: ["rita"]) { opened.append($0) }
        try await home.prepare()
        await home.refreshNotifications()

        await home.openNotification(try #require(home.uiModel.notifications.first))
        #expect(!hasDot(home))
        #expect(opened == ["requests"])
    }

    @Test func HOME_R04_readStaysReadAfterTheNextRead() async throws {
        let (home, _) = makeHome(requests: ["rita"])
        try await home.prepare()
        await home.refreshNotifications()
        await home.openNotification(try #require(home.uiModel.notifications.first))

        // The public database answers without knowing yet that it was read.
        await home.refreshNotifications()
        #expect(home.uiModel.notifications.map(\.isRead) == [true])
        #expect(!hasDot(home))
    }

    @Test func HOME_R04b_newFriend_opensOnlyTheirProfile_noTable() async throws {
        var opened: [String] = []
        let marina = Friend(id: "marina", name: "Marina", map: HomeContentModel.full.palateMap,
                            addedAt: now.addingTimeInterval(-3600))
        let (home, _) = makeHome(requests: [], friends: [marina]) { opened.append($0) }
        try await home.prepare()
        await home.refreshNotifications()

        let notification = try #require(home.uiModel.notifications.first {
            if case .newFriend = $0.kind { true } else { false }
        })
        await home.openNotification(notification)
        #expect(opened == ["friend-marina"])
    }
}
