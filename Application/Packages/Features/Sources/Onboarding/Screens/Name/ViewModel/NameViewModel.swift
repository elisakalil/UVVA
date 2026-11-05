import Observation

@MainActor @Observable
final class NameViewModel {
    private let draft: OnboardingDraft
    private weak var coordinator: (any OnboardingCoordinatorProtocol)?

    init(draft: OnboardingDraft, coordinator: any OnboardingCoordinatorProtocol) {
        self.draft = draft
        self.coordinator = coordinator
    }

    var name: String {
        get { draft.name }
        set { draft.name = newValue }
    }

    var nameIsValid: Bool { NameValidator.isValid(name) }

    func back() { coordinator?.back() }

    func continueFromName() {
        guard nameIsValid else { return }
        name = NameValidator.normalized(name)
        coordinator?.continueFromName()
    }
}
