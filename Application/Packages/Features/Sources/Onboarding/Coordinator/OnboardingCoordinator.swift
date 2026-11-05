import Core
import Observation

/// Applies valid transitions; the application decides what follows onboarding.
@MainActor @Observable
final class OnboardingCoordinator: OnboardingCoordinatorProtocol {
    private(set) var flow = OnboardingFlow()
    private let draft: OnboardingDraft
    private let onFinish: (OnboardingResult) -> Void

    init(draft: OnboardingDraft, onFinish: @escaping (OnboardingResult) -> Void) {
        self.draft = draft
        self.onFinish = onFinish
    }

    var step: OnboardingStep { flow.step }

    func back() {
        if step == .name { draft.identity = nil }
        flow.back()
    }

    func openLegal(_ tab: LegalTab) { flow.openLegal(tab) }

    func signedIn(_ identity: AuthIdentity) {
        guard step == .welcome else { return }
        draft.identity = identity
        flow.signedIn()
    }

    func accountLookedUp(_ account: ExistingOnboardingAccount?) {
        guard step == .lookingUpAccount else { return }
        flow.accountLookedUp(exists: account != nil)
        if let account {
            onFinish(.existingAccount(account.profile, hasMap: account.hasMap))
        } else {
            draft.name = draft.identity?.givenName ?? ""
        }
    }

    func continueFromName() {
        guard step == .name else { return }
        flow.next()
    }

    func accountCreated(_ profile: Profile) {
        guard step == .phone else { return }
        draft.profile = profile
        flow.next()
    }

    func contactsAnswered(granted: Bool) {
        guard step == .findFriends else { return }
        flow.contactsAnswered(granted: granted)
        if step == .done { finishNewAccount() }
    }

    func finishContacts() {
        guard step == .contacts else { return }
        flow.next()
        finishNewAccount()
    }

    private func finishNewAccount() {
        guard let profile = draft.profile else { return }
        onFinish(.newAccount(profile))
    }
}
