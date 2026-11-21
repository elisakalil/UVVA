import Foundation

/// Which of the Home's notifications the user opened (HOME-R04). The notifications themselves are worked out again
/// on every load; only this is kept, in the Personal store, so it follows the user to their other devices.
public protocol NotificationsRepository: Sendable {
    func readNotifications() async throws -> Set<String>
    func markRead(_ id: String) async throws
}
