import Core
import Foundation

@MainActor
struct DeleteAccountUseCase: DeleteAccountUseCaseProtocol {
    let social: any SocialService
    let profiles: any ProfileRepository
    let scheduler: any ReminderScheduling

    /// Stop on public deletion failure; private data and notifications must remain intact.
    func execute(_ profile: Profile) async throws {
        try await social.deleteAccount(userID: profile.id, phone: profile.phone)
        try await profiles.deleteAccount()
        await scheduler.schedule(nil)
    }
}
