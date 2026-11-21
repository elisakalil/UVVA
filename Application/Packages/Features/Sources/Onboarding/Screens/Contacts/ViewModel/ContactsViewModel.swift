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
    /// "Next" in the Onboarding; "Done" when opened from the Friends tab.
    private let finishText: String?
    /// The user's map for the invite picture; none during the Onboarding.
    private let loadMap: () async -> PalateMap?
    private var inviteMap: PalateMap? { didSet { refresh() } }
    /// Invites kept on the device, so they show as "Invited" here and, faded, in the Friends tab (FRI-R04b).
    private let invites: (any FriendsRepository)?
    private let findContactsUseCase: any FindContactsOnUVVAUseCaseProtocol
    private let sendRequestUseCase: any SendFriendRequestUseCaseProtocol
    private weak var coordinator: (any OnboardingCoordinatorProtocol)?

    init(draft: OnboardingDraft, findContactsUseCase: any FindContactsOnUVVAUseCaseProtocol,
         sendRequestUseCase: any SendFriendRequestUseCaseProtocol,
         coordinator: any OnboardingCoordinatorProtocol, finishText: String? = nil,
         loadMap: @escaping () async -> PalateMap? = { nil }, invites: (any FriendsRepository)? = nil) {
        self.draft = draft
        self.invites = invites
        self.finishText = finishText
        self.loadMap = loadMap
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
        inviteMap = await loadMap()
        if let saved = try? await invites?.invitedContacts() {
            invited.formUnion(saved.map(\.id))
        }
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

    func markInvited(_ contactID: String) {
        invited.insert(contactID)
        guard let invites, let contact = discovered.toInvite.first(where: { $0.id == contactID }) else { return }
        let invite = InvitedContact(id: contact.id, name: contact.displayName, phones: contact.phones, invitedAt: .now)
        Task { try? await invites.saveInvite(invite) }
    }

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
        model.inviteName = draft.profile?.firstName ?? draft.name
        model.inviteMap = inviteMap
        if let finishText { model.nextText = finishText }
        uiModel = model
    }
}
