import Core
import Foundation

public struct ReminderUIModel {
    var draft = ReminderDraft(nil)
    var customTime = Date.now
    var isSaving = false
    var notice: String?
    var moments: [(ReminderMoment, String)] { [
        (.coffee, String(localized: "With my coffee", bundle: .module)),
        (.lunch, String(localized: "Around lunch", bundle: .module)),
        (.dinner, String(localized: "Before dinner", bundle: .module)),
        (.late, String(localized: "Late, with a glass", bundle: .module))
    ] }

    static func dayLabel(_ weekday: Int) -> String {
        Calendar(identifier: .gregorian).shortWeekdaySymbols[weekday - 1]
    }

    var summary: String {
        if draft.isOff { return String(localized: "No reminders. You open the app whenever you feel like it.", bundle: .module) }
        guard let reminder = draft.reminder else {
            return String(localized: "Pick a moment and at least one day.", bundle: .module)
        }
        let days = ReminderDraft.week.filter(reminder.weekdays.contains).map(Self.dayLabel).joined(separator: ", ")
        return String(localized: "At \(reminder.time) on \(days).", bundle: .module)
    }

    var dailyReminderText = String(localized: "Daily reminder", bundle: .module)
    var turnRemindersOffText = String(localized: "Turn reminders off", bundle: .module)
    var youOpenTheAppWheneverText = String(localized: "You open the app whenever you feel like it.", bundle: .module)
    var daysText = String(localized: "Days", bundle: .module)
    var saveText = String(localized: "Save", bundle: .module)
    var pickTheMomentOfTheText = String(localized: "Pick the moment of the day and the days of the week. Change it whenever you like.", bundle: .module)
    var theReminderCouldNotBeText = String(localized: "The reminder could not be saved. Try again.", bundle: .module)
    var anotherTimeText = String(localized: "Another time", bundle: .module)
}
