import Foundation

/// The daily reminder (YOU-R16 to R20): a time and the days of the week.
public struct Reminder: Equatable, Sendable {
    public var hour: Int
    public var minute: Int
    /// Calendar weekdays, 1 = Sunday … 7 = Saturday.
    public var weekdays: Set<Int>

    public init(hour: Int, minute: Int = 0, weekdays: Set<Int>) {
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
    }

    /// "19:00"
    public var time: String { String(format: "%02d:%02d", hour, minute) }
}
