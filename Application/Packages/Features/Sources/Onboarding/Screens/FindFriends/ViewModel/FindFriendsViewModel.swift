import Combine

@MainActor
final class FindFriendsViewModel: FindFriendsViewModelProtocol {
    @Published private(set) var uiModel = FindFriendsUIModel()
    private let requestAccessUseCase: any RequestContactsAccessUseCaseProtocol
    private weak var coordinator: (any OnboardingCoordinatorProtocol)?

    init(requestAccessUseCase: any RequestContactsAccessUseCaseProtocol,
         coordinator: any OnboardingCoordinatorProtocol) {
        self.requestAccessUseCase = requestAccessUseCase
        self.coordinator = coordinator
    }

    func findFriends() async {
        guard !uiModel.isAsking else { return }
        uiModel.isAsking = true
        defer { uiModel.isAsking = false }
        let granted = await requestAccessUseCase.execute()
        coordinator?.contactsAnswered(granted: granted)
    }
}
