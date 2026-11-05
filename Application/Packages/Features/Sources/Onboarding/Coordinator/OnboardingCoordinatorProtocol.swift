import Core

@MainActor
protocol OnboardingCoordinatorProtocol: AnyObject {
    func back()
    func openLegal(_ tab: LegalTab)
    func signedIn(_ identity: AuthIdentity)
    func accountLookedUp(_ account: ExistingOnboardingAccount?)
    func continueFromName()
    func accountCreated(_ profile: Profile)
    func contactsAnswered(granted: Bool)
    func finishContacts()
}
