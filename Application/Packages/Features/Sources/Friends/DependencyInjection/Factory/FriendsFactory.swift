import Core
import CoreUI
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
    /// Which wines the Cellar holds, for the wine sheet of a friend's Map (FRI-R11).
    private let cellar: (any CellarRepository)?
    /// FRI-R11b, R11c: sending wines to friends, and the catalog the wines received are read from.
    private let sharing: (any WineSharingService)?
    private let wines: (any WineLookup)?
    /// FRI-R12a: the app's label scanner, which hands over the wine it reads.
    private let makeWineScan: ((@escaping (Wine) -> Void) -> NewNoteViewModel)?
    private let homeCountry: PhoneCountry
    private let now: () -> Date

    public init(profiles: any ProfileRepository, maps: any PalateMapRepository, friends: any FriendsRepository,
                catalog: any CatalogRepository,
                social: any SocialService, contacts: any ContactsProviding, cellar: (any CellarRepository)? = nil,
                sharing: (any WineSharingService)? = nil, wines: (any WineLookup)? = nil,
                makeWineScan: ((@escaping (Wine) -> Void) -> NewNoteViewModel)? = nil,
                homeCountry: PhoneCountry = PhoneCountries.defaultCountry(), now: @escaping () -> Date = Date.init) {
        self.profiles = profiles
        self.maps = maps
        self.friends = friends
        self.catalog = catalog
        self.social = social
        self.contacts = contacts
        self.cellar = cellar
        self.sharing = sharing
        self.wines = wines
        self.makeWineScan = makeWineScan
        self.homeCountry = homeCountry
        self.now = now
    }

    /// The tab. `onFriendsChange` lets the app refresh the Home's friends card (HOME-R11); `onAddToCellar` opens the
    /// Cellar's new note for a wine a friend sent (FRI-R11c) or one read for the user and the friend(s);
    /// `onHasFriends` lets the app ask for pushes.
    public func makeViewModel(onFriendsChange: @escaping () -> Void = {},
                              onAddFriends: @escaping () -> Void = {},
                              onAddToCellar: @escaping (Wine) -> Void = { _ in },
                              onHasFriends: @escaping () -> Void = {}) -> FriendsViewModel {
        let cellarWines = CellarWinesUseCase(cellar: cellar)
        let shareWine = ShareWineUseCase(sharing: sharing, wines: wines)
        let buildTable = BuildTableUseCase(catalog: catalog, now: now)
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
            shareWine: shareWine,
            cellarWines: cellarWines,
            pendingInvites: PendingInvitesUseCase(friends: friends, social: social, homeCountry: homeCountry),
            makeProfile: { friend, user, setsTable, owner in
                FriendProfileViewModel(friend: friend, user: user, setsTable: setsTable, buildTable: buildTable,
                                       lastTable: lastTable, removeFriend: remove, shareWine: shareWine,
                                       makeWineScan: makeWineScan, cellarWines: cellarWines,
                                       onAddToCellar: onAddToCellar,
                                       onRemoved: { [weak owner] id in owner?.friendRemoved(id) },
                                       onClose: { [weak owner] in owner?.closeFriend() })
            },
            makeGroupTable: { members, user, owner in
                GroupTableViewModel(friends: members, user: user, buildTable: buildTable, lastTable: lastTable,
                                    shareWine: shareWine, makeWineScan: makeWineScan, cellarWines: cellarWines,
                                    onAddToCellar: onAddToCellar,
                                    onClose: { [weak owner] in owner?.closeGroupTable() })
            },
            now: now,
            onFriendsChange: onFriendsChange,
            onAddFriends: onAddFriends,
            onAddToCellar: onAddToCellar,
            onHasFriends: onHasFriends)
    }
}
