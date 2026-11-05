import Core
import Foundation
import Observation

@MainActor @Observable
final class ReminderViewModel {
    var draft = ReminderDraft(nil)
    var customTime = Date.now
    private(set) var isSaving = false
    private(set) var notice: String?
    private let state: YouState
    private let saveReminderUseCase: any SaveReminderUseCaseProtocol

    init(state: YouState, saveReminderUseCase: any SaveReminderUseCaseProtocol) {
        self.state = state
        self.saveReminderUseCase = saveReminderUseCase
    }

    func prepare() {
        let reminder = state.content.reminder
        draft = ReminderDraft(reminder)
        customTime = Calendar.current.date(from: DateComponents(hour: reminder?.hour ?? 20,
                                                                minute: reminder?.minute ?? 0)) ?? .now
        notice = nil
    }

    func saveReminder(_ reminder: Reminder?) async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        notice = nil
        defer { isSaving = false }
        do {
            try await saveReminderUseCase.execute(reminder, previous: state.content.reminder)
            state.content.reminder = reminder
            return true
        } catch {
            notice = String(localized: "The reminder could not be saved. Try again.", bundle: .module)
            return false
        }
    }
}
