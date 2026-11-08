import Core
import Foundation

/// Composition root for Friends. The app injects the repositories and services.
@MainActor
public struct FriendsFactory: FriendsFactoryProtocol {
    private let profiles: any ProfileRepository
    private let maps: any PalateMapRepository
    private let friends: any FriendsRepository
    private let catalog: any CatalogRepository
    private let social: any SocialService
    private let contacts: any ContactsProviding
    private let homeCountry: PhoneCountry
    private let now: () -> Date

    public init(profiles: any ProfileRepository, maps: any PalateMapRepository, friends: any FriendsRepository,
                catalog: any CatalogRepository,
                social: any SocialService, contacts: any ContactsProviding,
                homeCountry: PhoneCountry = PhoneCountries.defaultCountry(), now: @escaping () -> Date = Date.init) {
        self.profiles = profiles
        self.maps = maps
        self.friends = friends
        self.catalog = catalog
        self.social = social
        self.contacts = contacts
        self.homeCountry = homeCountry
        self.now = now
    }

    /// The tab. `onFriendsChange` lets the app refresh the Home's friends card (HOME-R11).
    public func makeViewModel(onFriendsChange: @escaping () -> Void = {}) -> FriendsViewModel {
        let buildTable = BuildTableUseCase(catalog: catalog)
        let lastTable = LastTableUseCase(friends: friends)
        let remove = RemoveFriendUseCase(social: social, friends: friends)
        return FriendsViewModel(
            loadUser: LoadUserUseCase(profiles: profiles, maps: maps),
            refreshFriends: RefreshFriendsUseCase(social: social, friends: friends),
            findQuickAdd: FindQuickAddUseCase(contacts: contacts, social: social, friends: friends, homeCountry: homeCountry),
            sendRequest: SendFriendRequestUseCase(social: social),
            declineRequest: DeclineRequestUseCase(friends: friends),
            dismiss: DismissSuggestionUseCase(friends: friends),
            cancel: CancelRequestUseCase(social: social),
            contacts: ContactsAccessUseCase(contacts: contacts),
            lastTable: lastTable,
            makeProfile: { friend, user, tab, owner in
                FriendProfileViewModel(friend: friend, user: user, tab: tab, buildTable: buildTable,
                                       lastTable: lastTable, removeFriend: remove,
                                       onRemoved: { [weak owner] id in owner?.friendRemoved(id) },
                                       onClose: { [weak owner] in owner?.closeFriend() })
            },
            makeGroupTable: { members, user, owner in
                GroupTableViewModel(friends: members, user: user, buildTable: buildTable, lastTable: lastTable,
                                    onClose: { [weak owner] in owner?.closeGroupTable() })
            },
            now: now,
            onFriendsChange: onFriendsChange)
    }
}
