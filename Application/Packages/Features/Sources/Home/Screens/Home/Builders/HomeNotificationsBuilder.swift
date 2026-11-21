import Core
import Foundation
import Match

/// What the notifications are made of besides the Home's own data: the requests and wines friends sent, read from
/// the public database, and which notifications the user already opened.
struct HomeNotificationSources: Equatable, Sendable {
    struct Request: Equatable, Sendable {
        var userID: String
        var name: String
        var sentAt: Date
    }

    var requests: [Request] = []
    var wines: [SharedWineRecord] = []
    var read: Set<String> = []
}

/// HOME-R04a: the notifications, worked out from what already happened. Pure: no clock of its own (SHARED-R04).
struct HomeNotificationsBuilder: Sendable {
    /// How far back the list goes.
    static let window: TimeInterval = 30 * 24 * 3600
    /// A lesson left this long is waiting.
    static let lessonWait: TimeInterval = 24 * 3600
    static let limit = 30

    func build(from model: HomeContentModel, sources: HomeNotificationSources, now: Date) -> [AppNotification] {
        var list: [AppNotification] = []

        for request in sources.requests {
            list.append(.init(id: "request-\(request.userID)-\(Self.stamp(request.sentAt))",
                              kind: .friendRequest(userID: request.userID, name: request.name),
                              date: request.sentAt, isRead: false))
        }
        for friend in model.friends {
            list.append(.init(id: "friend-\(friend.id)-\(Self.stamp(friend.addedAt))",
                              kind: .newFriend(friendID: friend.id, name: friend.name,
                                               compatibility: TableMatch.compatibility(model.palateMap, friend.map)),
                              date: friend.addedAt, isRead: false))
        }
        // Sending a wine again moves it to the top and pushes again (FRI-R11c): it is a new notification too.
        for wine in sources.wines {
            list.append(.init(id: "wine-\(wine.id)-\(Self.stamp(wine.sentAt))",
                              kind: .wineReceived(id: wine.id, from: wine.fromName, wine: wine.wineName),
                              date: wine.sentAt, isRead: false))
        }
        if let rating = model.lastRating, let change = HomeCardsBuilder().axisChanged(rating), change.delta != 0 {
            list.append(.init(id: "map-\(rating.wineKey)-\(Self.stamp(rating.date))",
                              kind: .mapMoved(axis: change.axis, delta: change.delta),
                              date: rating.date, isRead: false))
        }
        // Only the lesson the Continue card offers (HOME-R12, R13): one nudge, not one per course started.
        if let course = HomeCardsBuilder().continueLesson(model.courses), let opened = course.lastOpenedAt,
           let lesson = course.current, now.timeIntervalSince(opened) >= Self.lessonWait {
            list.append(.init(id: "lesson-\(course.id)-\(lesson.number)",
                              kind: .lessonWaiting(courseID: course.id, course: course.title, lesson: lesson.number),
                              date: opened.addingTimeInterval(Self.lessonWait), isRead: false))
        }

        let oldest = now.addingTimeInterval(-Self.window)
        return list
            .filter { $0.date >= oldest }
            .map { notification in
                var notification = notification
                // A clock a little ahead on the sender's phone does not put a notification in the future.
                notification.date = min(notification.date, now)
                notification.isRead = sources.read.contains(notification.id)
                return notification
            }
            .sorted { $0.date == $1.date ? $0.id < $1.id : $0.date > $1.date }
            .prefix(Self.limit)
            .map { $0 }
    }

    private static func stamp(_ date: Date) -> Int { Int(date.timeIntervalSince1970) }
}
