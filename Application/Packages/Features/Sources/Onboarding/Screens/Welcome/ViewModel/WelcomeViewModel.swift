import Core
import Foundation
import Combine

@MainActor
final class WelcomeViewModel: WelcomeViewModelProtocol {
    @Published private(set) var uiModel = WelcomeUIModel()

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

    func checkICloud() async { uiModel.iCloudAvailable = await cloud.isAvailable() }

    func openLegal(_ tab: LegalTab) { coordinator?.openLegal(tab) }

    func signIn() async {
        guard uiModel.iCloudAvailable == true, !uiModel.isSigningIn else { return }
        uiModel.isSigningIn = true
        uiModel.notice = nil
        defer { uiModel.isSigningIn = false }
        do {
            guard let identity = try await signInUseCase.execute() else { return }
            coordinator?.signedIn(identity)
            let account = await findAccountUseCase.execute(userID: identity.userID)
            coordinator?.accountLookedUp(account)
        } catch {
            uiModel.notice = uiModel.signInError
        }
    }
}
