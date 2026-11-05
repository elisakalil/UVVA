/// The composed onboarding flow. Only the root View consumes its screen models.
@MainActor
public struct OnboardingModule {
    let draft: OnboardingDraft
    let coordinator: OnboardingCoordinator
    let welcome: WelcomeViewModel
    let name: NameViewModel
    let phone: PhoneViewModel
    let findFriends: FindFriendsViewModel
    let contacts: ContactsViewModel
}
