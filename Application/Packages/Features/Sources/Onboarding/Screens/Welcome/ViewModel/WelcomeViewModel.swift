import Core
import Foundation
import Observation

@MainActor @Observable
final class WelcomeViewModel {
    private(set) var iCloudAvailable: Bool?
    private(set) var isSigningIn = false
    private(set) var notice: String?

    private let cloud: any CloudAccountStatus
    private let signInUseCase: any SignInUseCaseProtocol
    private let findAccountUseCase: any FindExistingAccountUseCaseProtocol
    private weak var coordinator: (any OnboardingCoordinatorProtocol)?

    init(cloud: any CloudAccountStatus, signInUseCase: any SignInUseCaseProtocol,
         findAccountUseCase: any FindExistingAccountUseCaseProtocol,
         coordinator: any OnboardingCoordinatorProtocol) {
        self.cloud = cloud
        self.signInUseCase = signInUseCase
        self.findAccountUseCase = findAccountUseCase
        self.coordinator = coordinator
    }

    func checkICloud() async { iCloudAvailable = await cloud.isAvailable() }

    func openLegal(_ tab: LegalTab) { coordinator?.openLegal(tab) }

    func signIn() async {
        guard iCloudAvailable == true, !isSigningIn else { return }
        isSigningIn = true
        notice = nil
        defer { isSigningIn = false }
        do {
            guard let identity = try await signInUseCase.execute() else { return }
            coordinator?.signedIn(identity)
            let account = await findAccountUseCase.execute(userID: identity.userID)
            coordinator?.accountLookedUp(account)
        } catch {
            notice = String(localized: "Could not reach Apple. Check your connection and try again.", bundle: .module)
        }
    }
}
