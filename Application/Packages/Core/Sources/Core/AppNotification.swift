import Foundation

/// One line of the Home's notifications (HOME-R04, R04a). Worked out on the phone from the user's own data and from
/// the requests and wines friends send; only whether it was read is kept (`NotificationsRepository`).
public struct AppNotification: Identifiable, Equatable, Sendable {
    /// What happened, and so where tapping it leads (HOME-R04b).
    public enum Kind: Equatable, Sendable {
        /// Someone asked to compare palates (FRI-R08a): the Friends tab, where the request is answered.
        case friendRequest(userID: String, name: String)
        /// A request crossed and the two became friends: that friend's profile, with no table set (FRI-R10).
        case newFriend(friendID: String, name: String, compatibility: Int)
        /// A friend sent a wine (FRI-R11c): the wine, over the Friends tab.
        case wineReceived(id: String, from: String, wine: String)
        /// The last wine rated moved the map (HOME-R15): You › Map, at "Over time".
        case mapMoved(axis: PalateAxis, delta: Double)
        /// A lesson started and left for a day (HOME-R12): the course, at that lesson.
        case lessonWaiting(courseID: String, course: String, lesson: Int)
    }

    /// Stable for the same event, so a notification read stays read on every load.
    public var id: String
    public var kind: Kind
    /// When it happened; the list shows the newest first.
    public var date: Date
    public var isRead: Bool

    public init(id: String, kind: Kind, date: Date, isRead: Bool) {
        self.id = id
        self.kind = kind
        self.date = date
        self.isRead = isRead
    }
}
