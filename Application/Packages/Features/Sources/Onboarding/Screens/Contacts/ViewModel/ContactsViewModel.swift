import Core
import Foundation
import Observation

@MainActor @Observable
final class ContactsViewModel {
    private(set) var isLoadingContacts = false
    private(set) var discovered = DiscoveredContacts()
    private(set) var requested: Set<String> = []
    private(set) var invited: Set<String> = []
    var contactsQuery = ""

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
    }

    func back() { coordinator?.back() }

    func loadContacts() async {
        guard !isLoadingContacts else { return }
        isLoadingContacts = true
        defer { isLoadingContacts = false }
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

    var inviteMessage: String {
        String(localized: "Map your taste in wine with me on UVVA.", bundle: .module)
    }

    var inviteLink: URL? { draft.profile?.inviteLink }

    func finishContacts() { coordinator?.finishContacts() }

    var contactsModel: ContactsUIModel {
        ContactsPresentationBuilder().build(from: discovered, query: contactsQuery,
                                             requested: requested, invited: invited,
                                             isLoadingContacts: isLoadingContacts)
    }
}
