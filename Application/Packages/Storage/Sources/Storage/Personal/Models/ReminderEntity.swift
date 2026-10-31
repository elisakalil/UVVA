import Foundation
import SwiftData

/// The daily reminder, in the Personal store (ARCHITECTURE §2.1, `Reminder`: slot, days).
@Model
public final class ReminderEntity {
    public var hour = 19
    public var minute = 0
    /// Calendar weekdays, 1 = Sunday … 7 = Saturday.
    public var weekdays: [Int] = []

    init(hour: Int, minute: Int, weekdays: [Int]) {
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
    }
}
