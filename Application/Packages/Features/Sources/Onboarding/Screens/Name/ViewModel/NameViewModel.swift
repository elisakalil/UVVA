import Combine

@MainActor
final class NameViewModel: NameViewModelProtocol {
    @Published private(set) var uiModel = NameUIModel()
    private var nameSubscription: AnyCancellable?
    private let draft: OnboardingDraft
    private weak var coordinator: (any OnboardingCoordinatorProtocol)?

    init(draft: OnboardingDraft, coordinator: any OnboardingCoordinatorProtocol) {
        self.draft = draft
        self.coordinator = coordinator
        nameSubscription = draft.$name.sink { [weak self] name in self?.uiModel.name = name }
    }

    func updateName(_ name: String) { draft.name = name }

    func back() { coordinator?.back() }

    func continueFromName() {
        guard uiModel.isValid else { return }
        draft.name = NameValidator.normalized(uiModel.name)
        coordinator?.continueFromName()
    }
}
