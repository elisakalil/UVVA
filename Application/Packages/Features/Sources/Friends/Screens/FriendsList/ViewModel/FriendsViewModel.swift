import Combine
import Core
import Foundation
import OSLog

/// The Friends tab (FRIENDS.md §4): requests, friends and Quick add. Every change shows at once and is taken back
/// if the public database refuses it.
@MainActor
public final class FriendsViewModel: FriendsViewModelProtocol {
    @Published public private(set) var uiModel = FriendsUIModel()
    @Published public private(set) var profile: FriendProfileViewModel?
    @Published public private(set) var groupTable: GroupTableViewModel?

    /// No push yet (D10): the requests are read when the tab opens, at most this often.
    static let refreshInterval: TimeInterval = 30
    /// D6: a table seats six, the user and five friends.
    static let maxFriendsAtTable = 5

    private var content = FriendsContentModel() { didSet { refresh() } }
    private var isInviting = false { didSet { refresh() } }
    private var isSelecting = false { didSet { refresh() } }
    /// In the order they were picked.
    private var selected: [String] = [] { didSet { refresh() } }
    private var query = "" { didSet { refresh() } }
    private var lastRefresh: Date?
    /// FRI-R11c: the wine received open full screen, the wines the Cellar held when it opened, and the one handed to
    /// the new note once it is gone.
    private var openedReceived: ReceivedWine? { didSet { refresh() } }
    private var cellarWineKeys: Set<String> = []
    private var wineForCellar: Wine?
    private var toldHasFriends = false
    private var toastTask: Task<Void, Never>?

    private let loadUser: any LoadUserUseCaseProtocol
    private let refreshFriends: any RefreshFriendsUseCaseProtocol
    private let findQuickAdd: any FindQuickAddUseCaseProtocol
    private let sendRequest: any SendFriendRequestUseCaseProtocol
    private let declineRequest: any DeclineRequestUseCaseProtocol
    private let dismiss: any DismissSuggestionUseCaseProtocol
    private let cancel: any CancelRequestUseCaseProtocol
    private let contacts: any ContactsAccessUseCaseProtocol
    private let lastTable: any LastTableUseCaseProtocol
    private let shareWine: any ShareWineUseCaseProtocol
    private let cellarWines: any CellarWinesUseCaseProtocol
    private let pendingInvites: (any PendingInvitesUseCaseProtocol)?
    /// The friend, the user, and whether the profile opens with the table set (HOME-R11).
    private let makeProfile: (Friend, FriendsUser, _ setsTable: Bool, _ owner: FriendsViewModel) -> FriendProfileViewModel
    private let makeGroupTable: ([Friend], FriendsUser, _ owner: FriendsViewModel) -> GroupTableViewModel
    private let toastDuration: Duration
    private let now: () -> Date
    /// The friends changed: the app tells the Home (HOME-R11).
    private let onFriendsChange: () -> Void
    /// FRI-R06: the app opens the contacts list of the Onboarding.
    private let onAddFriends: () -> Void
    /// "Add to cellar" on a wine received: the app opens the Cellar's new note.
    private let onAddToCellar: (Wine) -> Void
    /// FRI-R11c: the user has a friend, so the app asks to send pushes for the wines they will send. Once per session.
    private let onHasFriends: () -> Void
    private let logger = Logger(subsystem: "app.uvva", category: "friends")

    init(loadUser: any LoadUserUseCaseProtocol, refreshFriends: any RefreshFriendsUseCaseProtocol,
         findQuickAdd: any FindQuickAddUseCaseProtocol, sendRequest: any SendFriendRequestUseCaseProtocol,
         declineRequest: any DeclineRequestUseCaseProtocol, dismiss: any DismissSuggestionUseCaseProtocol,
         cancel: any CancelRequestUseCaseProtocol, contacts: any ContactsAccessUseCaseProtocol,
         lastTable: any LastTableUseCaseProtocol,
         shareWine: any ShareWineUseCaseProtocol = ShareWineUseCase(sharing: nil, wines: nil),
         cellarWines: any CellarWinesUseCaseProtocol = CellarWinesUseCase(cellar: nil),
         pendingInvites: (any PendingInvitesUseCaseProtocol)? = nil,
         makeProfile: @escaping (Friend, FriendsUser, Bool, FriendsViewModel) -> FriendProfileViewModel,
         makeGroupTable: @escaping ([Friend], FriendsUser, FriendsViewModel) -> GroupTableViewModel,
         toastDuration: Duration = .seconds(3), now: @escaping () -> Date = Date.init,
         onFriendsChange: @escaping () -> Void = {}, onAddFriends: @escaping () -> Void = {},
         onAddToCellar: @escaping (Wine) -> Void = { _ in }, onHasFriends: @escaping () -> Void = {}) {
        self.loadUser = loadUser
        self.refreshFriends = refreshFriends
        self.findQuickAdd = findQuickAdd
        self.sendRequest = sendRequest
        self.declineRequest = declineRequest
        self.dismiss = dismiss
        self.cancel = cancel
        self.contacts = contacts
        self.lastTable = lastTable
        self.shareWine = shareWine
        self.cellarWines = cellarWines
        self.pendingInvites = pendingInvites
        self.onAddToCellar = onAddToCellar
        self.onHasFriends = onHasFriends
        self.makeProfile = makeProfile
        self.makeGroupTable = makeGroupTable
        self.toastDuration = toastDuration
        self.now = now
        self.onFriendsChange = onFriendsChange
        self.onAddFriends = onAddFriends
        refresh()
    }

    public func load() async { await update(force: false) }

    /// Reads ahead of the first visit, when the tabs open, so Friends shows at once.
    public func prefetch() async {
        guard lastRefresh == nil else { return }
        await update(force: false)
    }

    public func reload() async { await update(force: true) }

    private func update(force: Bool) async {
        do {
            // Every time: the map moves with each rating, and every compatibility with it.
            content.user = try await loadUser.execute()
        } catch {
            logger.error("Friends: profile did not load: \(error.localizedDescription, privacy: .public)")
        }
        guard let user = content.user else {
            content.isReady = true
            return
        }
        if lastRefresh == nil {
            content.snapshot.friends = await refreshFriends.cached()
            if !content.snapshot.friends.isEmpty { content.isReady = true }
        }
        content.contactsAccess = contacts.current()

        if !force, let lastRefresh, now().timeIntervalSince(lastRefresh) < Self.refreshInterval { return }
        lastRefresh = now()
        let before = Set(content.snapshot.friends.map(\.id))
        do {
            content.snapshot = try await refreshFriends.execute(userID: user.id)
        } catch {
            logger.error("Friends did not refresh: \(error.localizedDescription, privacy: .public)")
        }
        content.isLoading = false
        await findSuggestions()
        content.received = await shareWine.received(userID: user.id)
        content.invites = await pendingInvites?.execute() ?? []
        content.isReady = true
        if Set(content.snapshot.friends.map(\.id)) != before { onFriendsChange() }
        if !content.snapshot.friends.isEmpty, !toldHasFriends {
            toldHasFriends = true
            onHasFriends()
        }
    }

    // MARK: FRI-R11c · Sent to you

    public func openReceived(_ id: String) async {
        let fetched: ReceivedWine?
        if let known = content.received.first(where: { $0.id == id }) {
            fetched = known
        } else {
            // From a push, before the tab read it.
            fetched = await shareWine.received(id: id)
            if let fetched { content.received.insert(fetched, at: 0) }
        }
        guard let fetched else { return }
        cellarWineKeys = await cellarWines.wineKeys()
        // From a push, over whatever was open: it closes first, so the wine can open over the tab.
        if profile != nil || groupTable != nil || isInviting {
            profile = nil
            groupTable = nil
            isInviting = false
            try? await Task.sleep(for: .milliseconds(600))
        }
        openedReceived = fetched
    }

    public func closeReceived() { openedReceived = nil }

    public func addReceivedToCellar() {
        wineForCellar = openedReceived?.wine
        openedReceived = nil
    }

    public func receivedDismissed() {
        guard let wine = wineForCellar else { return }
        wineForCellar = nil
        onAddToCellar(wine)
    }

    /// Quick add leaves out friends and whoever already asked the user; those the user asked stay, as "Requested".
    private func findSuggestions() async {
        guard let user = content.user else { return }
        let excluding = Set(content.snapshot.friends.map(\.id)).union(content.snapshot.incoming.map(\.id))
        content.suggestions = await findQuickAdd.execute(userID: user.id, excluding: excluding)
    }

    // MARK: FRI-R08a · Pedidos recebidos

    /// Accepting sends the request back: both are friends at once.
    public func accept(_ id: String) async {
        guard let user = content.user, let request = content.snapshot.incoming.first(where: { $0.id == id }) else { return }
        let before = content.snapshot
        content.snapshot.incoming.removeAll { $0.id == id }
        content.snapshot.friends.append(Friend(id: request.id, name: request.name, map: request.map, addedAt: now()))
        do {
            try await sendRequest.execute(from: user.id, to: id)
            showNewFriend(request.name)
            onFriendsChange()
        } catch {
            logger.error("Accept failed: \(error.localizedDescription, privacy: .public)")
            content.snapshot = before
        }
    }

    /// The request goes, and the sender is not told.
    public func decline(_ id: String) async {
        content.snapshot.incoming.removeAll { $0.id == id }
        do {
            try await declineRequest.execute(id)
        } catch {
            logger.error("Decline was not kept: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: FRI-R07 a R09 · Quick add

    public func add(_ id: String) async {
        guard let user = content.user, !content.snapshot.requested.contains(id) else { return }
        content.snapshot.requested.insert(id)
        do {
            try await sendRequest.execute(from: user.id, to: id)
        } catch {
            logger.error("Request was not sent: \(error.localizedDescription, privacy: .public)")
            content.snapshot.requested.remove(id)
        }
    }

    public func cancelRequest(_ id: String) async {
        guard let user = content.user, content.snapshot.requested.contains(id) else { return }
        content.snapshot.requested.remove(id)
        do {
            try await cancel.execute(from: user.id, to: id)
        } catch {
            logger.error("Request was not taken back: \(error.localizedDescription, privacy: .public)")
            content.snapshot.requested.insert(id)
        }
    }

    public func dismissSuggestion(_ id: String) async {
        content.suggestions.removeAll { $0.id == id }
        do {
            try await dismiss.execute(id)
        } catch {
            logger.error("Dismissal was not kept: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// FRI-R07a: asks again; with access given, the suggestions come in.
    public func askForContacts() async {
        content.contactsAccess = await contacts.request()
        await findSuggestions()
    }

    /// FRI-R06 "Invite friends": asks for the contacts first if iOS never did, then opens the contacts
    /// list. Refused, nothing opens: the tab offers the Settings instead.
    public func addFriends() async {
        if content.contactsAccess == .notDetermined {
            content.contactsAccess = await contacts.request()
            await findSuggestions()
        }
        guard content.contactsAccess == .granted else { return }
        onAddFriends()
    }

    // MARK: FRI-R10 · Um amigo

    public func openFriend(_ id: String) {
        open(id)
    }

    public func closeFriend() { profile = nil }

    /// HOME-R04b: a new-friend notification opens only that friend's profile, on its Map, with no table set. The
    /// friend may have just come in, so the public database is read again when they are not in the list yet.
    public func openFriendProfile(_ id: String) async {
        await load()
        if !content.snapshot.friends.contains(where: { $0.id == id }) { await reload() }
        open(id)
    }

    /// HOME-R11: the Home's match card opens the table with that friend (FRI-R13).
    public func openFriendTable(_ id: String) async {
        await load()
        open(id, setsTable: true)
    }

    /// HOME-R11, FRI-R17: the Home's match card opens the last table; before any, the table with the only friend.
    public func openLastTable() async {
        await load()
        let friends = content.snapshot.friends
        let saved = await lastTable.load()
        if let saved, saved.count >= 2 {
            let members = saved.compactMap { id in friends.first { $0.id == id } }
            if members.count >= 2 { return openGroupTable(members) }
        }
        let id: String? = if let saved, saved.count == 1, friends.contains(where: { $0.id == saved[0] }) {
            saved[0]
        } else if friends.count == 1 {
            friends[0].id
        } else {
            nil
        }
        if let id { open(id, setsTable: true) }
    }

    private func open(_ id: String, setsTable: Bool = false) {
        guard let user = content.user, let friend = content.snapshot.friends.first(where: { $0.id == id }) else { return }
        profile = makeProfile(friend, user, setsTable, self)
    }

    /// D4: the friend leaves the list, and the profile closes.
    func friendRemoved(_ id: String) {
        profile = nil
        content.snapshot.friends.removeAll { $0.id == id }
        onFriendsChange()
    }

    // MARK: Busca

    public func updateQuery(_ query: String) {
        self.query = query
    }

    // MARK: FRI-R18 · Mesa de grupo

    public func startSelecting() {
        selected = []
        query = ""
        isSelecting = true
    }

    public func cancelSelecting() {
        isSelecting = false
        selected = []
    }

    /// Picks a friend, or un-picks one already picked. Past the size of the table (D6) nothing is added.
    public func toggle(_ id: String) {
        guard isSelecting else { return }
        if let index = selected.firstIndex(of: id) {
            selected.remove(at: index)
        } else if selected.count < Self.maxFriendsAtTable, content.snapshot.friends.contains(where: { $0.id == id }) {
            selected.append(id)
        }
    }

    /// "Find a bottle for these [n]": opens the group table (FRI-R19).
    public func findBottle() {
        let members = selected.compactMap { id in content.snapshot.friends.first { $0.id == id } }
        guard members.count >= 2 else { return }
        isSelecting = false
        selected = []
        openGroupTable(members)
    }

    public func closeGroupTable() { groupTable = nil }

    private func openGroupTable(_ members: [Friend]) {
        guard let user = content.user else { return }
        groupTable = makeGroupTable(members, user, self)
    }

    // MARK: D2 · Convite

    public func openInvite() { isInviting = true }

    public func closeInvite() { isInviting = false }

    private func showNewFriend(_ name: String) {
        content.newFriendName = name
        toastTask?.cancel()
        toastTask = Task { [weak self, toastDuration] in
            try? await Task.sleep(for: toastDuration)
            guard !Task.isCancelled else { return }
            self?.content.newFriendName = nil
        }
    }

    private func refresh() {
        let builder = FriendsPresentationBuilder(content: content, resources: uiModel.resources)
        var model = uiModel
        model.countText = builder.countText
        model.friends = builder.friends(matching: query)
        model.pending = builder.pending
        model.query = query
        model.isSearching = !query.trimmingCharacters(in: .whitespaces).isEmpty
        model.requests = builder.requests
        model.received = builder.received
        model.receivedWine = openedReceived.flatMap { received in
            content.user.map { user in
                FriendWinePresentationBuilder(wine: received.wine, reader: .you(senderName: received.fromName, map: user.map),
                                              isInCellar: cellarWineKeys.contains(received.wine.id)).build()
            }
        }
        model.quickAdd = builder.quickAdd
        model.isEmpty = builder.isEmpty
        model.isLoading = content.isLoading
        model.isReady = content.isReady
        model.toastText = builder.toastText
        model.invite = builder.invite
        model.isInviting = isInviting && model.invite != nil
        model.canSelect = content.snapshot.friends.count >= 2
        model.isSelecting = isSelecting
        model.selectedIDs = Set(selected)
        model.selectButtonText = builder.selectButtonText(selected: selected.count)
        model.tableFullText = builder.tableFullText(selected: selected.count, limit: Self.maxFriendsAtTable)
        model.canFindBottle = selected.count >= 2
        uiModel = model
    }
}
