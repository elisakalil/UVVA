import Core
import Foundation

@MainActor
protocol FindExistingAccountUseCaseProtocol {
    func execute(userID: String) async -> ExistingOnboardingAccount?
}
