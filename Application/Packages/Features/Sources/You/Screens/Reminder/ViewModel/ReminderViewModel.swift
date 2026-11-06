import Core
import Foundation
import Combine

@MainActor
public final class ReminderViewModel: ReminderViewModelProtocol {
    @Published public private(set) var uiModel = ReminderUIModel()
    private let onReminderSaved: (Reminder?) -> Void
    private let readModel: () -> YouContentModel
    private let saveReminderUseCase: any SaveReminderUseCaseProtocol

    init(readModel: @escaping () -> YouContentModel, onReminderSaved: @escaping (Reminder?) -> Void, saveReminderUseCase: any SaveReminderUseCaseProtocol) {
        self.readModel = readModel
        self.onReminderSaved = onReminderSaved
        self.saveReminderUseCase = saveReminderUseCase
    }

    public func pick(_ moment: ReminderMoment) { uiModel.draft.pick(moment) }
    public func toggle(_ weekday: Int) { uiModel.draft.toggle(weekday) }
    public func turnOff() { uiModel.draft.turnOff() }
    public func updateTime(_ date: Date) {
        uiModel.customTime = date
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        uiModel.draft.pickTime(hour: parts.hour ?? 20, minute: parts.minute ?? 0)
    }

    public func prepare() {
        let reminder = readModel().reminder
        uiModel.draft = ReminderDraft(reminder)
        uiModel.customTime = Calendar.current.date(from: DateComponents(hour: reminder?.hour ?? 20,
                                                                minute: reminder?.minute ?? 0)) ?? .now
        uiModel.notice = nil
    }

    public func saveReminder(_ reminder: Reminder?) async -> Bool {
        guard !uiModel.isSaving else { return false }
        uiModel.isSaving = true
        uiModel.notice = nil
        defer { uiModel.isSaving = false }
        do {
            try await saveReminderUseCase.execute(reminder, previous: readModel().reminder)
            onReminderSaved(reminder)
            return true
        } catch {
            uiModel.notice = uiModel.theReminderCouldNotBeText
            return false
        }
    }
}
