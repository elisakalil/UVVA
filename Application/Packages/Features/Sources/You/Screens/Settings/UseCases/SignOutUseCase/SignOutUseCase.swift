import Core
import Foundation

@MainActor
struct SignOutUseCase: SignOutUseCaseProtocol {
    let scheduler: any ReminderScheduling

    func execute() async { await scheduler.schedule(nil) }
}
