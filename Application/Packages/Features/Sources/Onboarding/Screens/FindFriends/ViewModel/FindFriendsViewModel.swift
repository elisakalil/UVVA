import Observation

@MainActor @Observable
final class FindFriendsViewModel {
    private(set) var isAsking = false
    private let requestAccessUseCase: any RequestContactsAccessUseCaseProtocol
    private weak var coordinator: (any OnboardingCoordinatorProtocol)?

    init(requestAccessUseCase: any RequestContactsAccessUseCaseProtocol,
         coordinator: any OnboardingCoordinatorProtocol) {
        self.requestAccessUseCase = requestAccessUseCase
        self.coordinator = coordinator
    }

    func findFriends() async {
        guard !isAsking else { return }
        isAsking = true
        defer { isAsking = false }
        let granted = await requestAccessUseCase.execute()
        coordinator?.contactsAnswered(granted: granted)
    }
}
