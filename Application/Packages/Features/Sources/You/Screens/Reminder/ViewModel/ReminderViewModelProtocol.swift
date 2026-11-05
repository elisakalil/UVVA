import Combine
import Core
import Foundation

@MainActor
public protocol ReminderViewModelProtocol: ObservableObject {
    var uiModel: ReminderUIModel { get }
    func prepare()
    func pick(_ moment: ReminderMoment)
    func toggle(_ weekday: Int)
    func turnOff()
    func updateTime(_ date: Date)
    func saveReminder(_ reminder: Reminder?) async -> Bool
}
