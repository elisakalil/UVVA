@MainActor
public protocol OnboardingFactoryProtocol {
    func makeModule(onFinish: @escaping (OnboardingResult) -> Void) -> OnboardingModule
}
