import Foundation

/// Keeps the reminder in the Personal store.
public protocol ReminderRepository: Sendable {
    func reminder() async throws -> Reminder?
    /// Nil turns reminders off (YOU-R19).
    func save(_ reminder: Reminder?) async throws
}
