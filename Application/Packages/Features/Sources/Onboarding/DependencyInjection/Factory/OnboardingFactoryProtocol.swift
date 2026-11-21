import Core

@MainActor
public protocol OnboardingFactoryProtocol {
    func makeModule(onFinish: @escaping (OnboardingResult) -> Void) -> OnboardingModule
    func makeAddFriends(profile: Profile, onClose: @escaping () -> Void) -> AddFriendsModule
}
