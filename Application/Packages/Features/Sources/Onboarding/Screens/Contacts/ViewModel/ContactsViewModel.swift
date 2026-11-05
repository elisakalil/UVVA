import Core
import Foundation
import Combine

@MainActor
final class ContactsViewModel: ContactsViewModelProtocol {
    @Published private(set) var uiModel = ContactsUIModel(isLoading: false, title: nil, onUVVATitle: "",
                                                         onUVVA: [], toInvite: [], letters: [], noResults: false)
    private var discovered = DiscoveredContacts() { didSet { refresh() } }
    private var requested: Set<String> = [] { didSet { refresh() } }
    private var invited: Set<String> = [] { didSet { refresh() } }
    private var profileSubscription: AnyCancellable?

    private let draft: OnboardingDraft
    private let findContactsUseCase: any FindContactsOnUVVAUseCaseProtocol
    private let sendRequestUseCase: any SendFriendRequestUseCaseProtocol
    private weak var coordinator: (any OnboardingCoordinatorProtocol)?

    init(draft: OnboardingDraft, findContactsUseCase: any FindContactsOnUVVAUseCaseProtocol,
         sendRequestUseCase: any SendFriendRequestUseCaseProtocol,
         coordinator: any OnboardingCoordinatorProtocol) {
        self.draft = draft
        self.findContactsUseCase = findContactsUseCase
        self.sendRequestUseCase = sendRequestUseCase
        self.coordinator = coordinator
        profileSubscription = draft.$profile.sink { [weak self] profile in
            self?.uiModel.inviteLink = profile?.inviteLink
        }
    }

    func back() { coordinator?.back() }

    func loadContacts() async {
        guard !uiModel.isLoading else { return }
        uiModel.isLoading = true
        defer {
            uiModel.isLoading = false
            refresh()
        }
        discovered = await findContactsUseCase.execute(excluding: draft.profile?.id)
    }

    func add(_ contactID: String) async {
        guard let profile = draft.profile,
              let row = discovered.onUVVA.first(where: { $0.contact.id == contactID }),
              !requested.contains(contactID) else { return }
        requested.insert(contactID)
        do {
            try await sendRequestUseCase.execute(from: profile.id, to: row.account.id)
        } catch {
            requested.remove(contactID)
        }
    }

    func markInvited(_ contactID: String) { invited.insert(contactID) }

    func finishContacts() { coordinator?.finishContacts() }

    func updateQuery(_ query: String) {
        uiModel.query = query
        refresh()
    }

    private func refresh() {
        var model = ContactsPresentationBuilder().build(from: discovered, query: uiModel.query,
                                                        requested: requested, invited: invited,
                                                        isLoadingContacts: uiModel.isLoading)
        model.query = uiModel.query
        model.inviteLink = uiModel.inviteLink
        uiModel = model
    }
}
