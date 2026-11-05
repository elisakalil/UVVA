import Core
import Foundation

@MainActor
struct FindExistingAccountUseCase: FindExistingAccountUseCaseProtocol {
    let profiles: any ProfileRepository
    let maps: any PalateMapRepository
    let timeout: Duration

    func execute(userID: String) async -> ExistingOnboardingAccount? {
        guard let profile = try? await profiles.profile(authUserID: userID, waitingUpTo: timeout) else {
            return nil
        }
        let hasMap = ((try? await maps.currentMap()) ?? nil) != nil
        return ExistingOnboardingAccount(profile: profile, hasMap: hasMap)
    }
}
