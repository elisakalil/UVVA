import Core
import Foundation
import SwiftData

/// `ReminderRepository` on the Personal store. One reminder at most; none means reminders are off.
public actor ReminderStore: StoreActor, ReminderRepository {
    public nonisolated let executor: StoreExecutor

    public init(modelContainer: ModelContainer) {
        executor = StoreExecutor(modelContainer, label: "app.uvva.store.reminders")
    }

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
