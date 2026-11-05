import Core
import Foundation

@MainActor
protocol SaveReminderUseCaseProtocol {
    func execute(_ reminder: Reminder?, previous: Reminder?) async throws
}
