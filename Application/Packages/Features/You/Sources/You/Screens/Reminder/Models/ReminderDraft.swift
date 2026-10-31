import Core
import Foundation

/// The reminder being edited (YOU-R17 to R19): a moment or any time (D8), the days, or reminders off.
struct ReminderDraft: Equatable {
    /// Monday first, as the screen shows them (Calendar weekdays: 1 = Sunday).
    static let week = [2, 3, 4, 5, 6, 7, 1]

    private(set) var hour: Int?
    private(set) var minute = 0
    private(set) var weekdays: Set<Int>
    private(set) var isOff: Bool

    init(_ reminder: Reminder?) {
        hour = reminder?.hour
        minute = reminder?.minute ?? 0
        weekdays = reminder?.weekdays ?? []
        isOff = false
    }

    var moment: ReminderMoment? {
        hour.flatMap { ReminderMoment.matching(hour: $0, minute: minute) }
    }

    mutating func pick(_ moment: ReminderMoment) { pickTime(hour: moment.hour, minute: 0) }

    mutating func pickTime(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
        isOff = false
    }

    /// YOU-R19: no days, nothing to remind.
    mutating func turnOff() {
        isOff = true
        hour = nil
        weekdays = []
    }

    mutating func toggle(_ weekday: Int) {
        isOff = false
        if weekdays.contains(weekday) { weekdays.remove(weekday) } else { weekdays.insert(weekday) }
    }

    /// YOU-R18
    var canSave: Bool { isOff || (hour != nil && !weekdays.isEmpty) }

    /// What gets saved; nil turns reminders off.
    var reminder: Reminder? {
        guard !isOff, let hour, !weekdays.isEmpty else { return nil }
        return Reminder(hour: hour, minute: minute, weekdays: weekdays)
    }
}
