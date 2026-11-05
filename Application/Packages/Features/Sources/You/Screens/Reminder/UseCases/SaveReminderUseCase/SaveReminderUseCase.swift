import Core
import Foundation

@MainActor
struct SaveReminderUseCase: SaveReminderUseCaseProtocol {
    let reminders: any ReminderRepository
    let scheduler: any ReminderScheduling

    func execute(_ reminder: Reminder?, previous: Reminder?) async throws {
        if reminder != nil, previous == nil { _ = await scheduler.requestPermission() }
        try await reminders.save(reminder)
        await scheduler.schedule(reminder)
    }
}
