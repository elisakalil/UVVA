import Foundation

/// Local notifications for the reminder (YOU-R20).
public protocol ReminderScheduling: Sendable {
    /// Asks iOS the first time; true when notifications are allowed.
    func requestPermission() async -> Bool
    /// Replaces whatever was scheduled; nil leaves nothing scheduled.
    func schedule(_ reminder: Reminder?) async
}
