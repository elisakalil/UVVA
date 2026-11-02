import Core
import Foundation
import SwiftData

/// `ReminderRepository` on the Personal store. One reminder at most; none means reminders are off.
@ModelActor
public actor ReminderStore: ReminderRepository {
    public func reminder() throws -> Reminder? {
        try modelContext.fetch(FetchDescriptor<ReminderEntity>()).first.map {
            Reminder(hour: $0.hour, minute: $0.minute, weekdays: Set($0.weekdays))
        }
    }

    public func save(_ reminder: Reminder?) throws {
        for old in try modelContext.fetch(FetchDescriptor<ReminderEntity>()) { modelContext.delete(old) }
        if let reminder {
            modelContext.insert(ReminderEntity(hour: reminder.hour, minute: reminder.minute,
                                               weekdays: reminder.weekdays.sorted()))
        }
        try modelContext.save()
    }
}
