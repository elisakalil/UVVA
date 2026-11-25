import Combine
import Core
import CoreUI
import Foundation
import OSLog

/// A friend (FRIENDS.md §5): Map and Compatibility, with the table for two set from the foot of Compatibility, in its
/// own sheet (FRI-R15a). Setting it keeps it as the last table (FRI-R17).
@MainActor
public final class FriendProfileViewModel: FriendProfileViewModelProtocol {
    public nonisolated let id: String
    @Published public private(set) var uiModel = FriendProfileUIModel()

    private var tab: FriendProfileTab { didSet { refresh() } }
    /// FRI-R13: "Set the perfect dinner" was tapped at least once.
    private var isTableSet: Bool { didSet { refresh() } }
    /// FRI-R15a: the table's sheet is open.
    private var isTableOpen = false { didSet { refresh() } }
    /// FRI-R13a: the dinner the user chose, and the one the bottles were built for.
    private var preferences = DinnerPreferences() { didSet { refresh() } }
    private var builtFor = DinnerPreferences() { didSet { refresh() } }
    private var bottles: [TableBottle]? { didSet { refresh() } }
    private var giftWines: [Wine]? { didSet { refresh() } }
    private var isConfirmingRemoval = false { didSet { refresh() } }
    private var isSharing = false { didSet { refresh() } }
    /// The wine open in Friend Wine: one of the friend's Map (FRI-R11a) or one just scanned (FRI-R12a).
    private var openedWine: OpenedWine? { didSet { refresh() } }
    /// FRI-R11b: how far each wine's sending got, by wine.
    private var sending: [String: FriendWinePresentationBuilder.Sending] = [:] { didSet { refresh() } }
    /// FRI-R12a: the label scanner, while it is open, and the wine it read, until it is gone.
    private var scanner: NewNoteViewModel? { didSet { refresh() } }
    private var scannedWine: Wine?
    /// The wines the Cellar holds, read when a wine opens, and the one handed to the new note once Friend Wine is gone.
    private var cellarWineKeys: Set<String> = [] { didSet { refresh() } }
    private var wineForCellar: Wine?

    private enum OpenedWine {
        /// A wine of "Picks for [name]", read on the friend's map.
        case gift(String)
        /// A bottle of "Open this together", read on both maps.
        case table(String)
        /// A wine just scanned, read on both maps.
        case scanned(Wine)
    }

    private let friend: Friend
    private let user: FriendsUser
    private let buildTable: any BuildTableUseCaseProtocol
    private let lastTable: any LastTableUseCaseProtocol
    private let removeFriend: any RemoveFriendUseCaseProtocol
    private let shareWine: any ShareWineUseCaseProtocol
    private let makeWineScan: ((@escaping (Wine) -> Void) -> NewNoteViewModel)?
    private let cellarWines: any CellarWinesUseCaseProtocol
    /// "Add to cellar" on a wine for the two: the app opens the Cellar's new note over the friend.
    private let onAddToCellar: (Wine) -> Void
    private let onRemoved: (String) -> Void
    private let onClose: () -> Void
    private let logger = Logger(subsystem: "app.uvva", category: "friends")

    /// `setsTable`: opened as the last table (HOME-R11), on Compatibility with the dinner already set.
    init(friend: Friend, user: FriendsUser, tab: FriendProfileTab = .map, setsTable: Bool = false,
         buildTable: any BuildTableUseCaseProtocol, lastTable: any LastTableUseCaseProtocol,
         removeFriend: any RemoveFriendUseCaseProtocol,
         shareWine: any ShareWineUseCaseProtocol = ShareWineUseCase(sharing: nil, wines: nil),
         makeWineScan: ((@escaping (Wine) -> Void) -> NewNoteViewModel)? = nil,
         cellarWines: any CellarWinesUseCaseProtocol = CellarWinesUseCase(cellar: nil),
         onAddToCellar: @escaping (Wine) -> Void = { _ in },
         onRemoved: @escaping (String) -> Void = { _ in }, onClose: @escaping () -> Void = {}) {
        id = friend.id
        self.friend = friend
        self.user = user
        self.tab = setsTable ? .compatibility : tab
        isTableSet = setsTable
        // Opened as the last table: its sheet opens over Compatibility.
        isTableOpen = setsTable
        self.buildTable = buildTable
        self.lastTable = lastTable
        self.removeFriend = removeFriend
        self.shareWine = shareWine
        self.makeWineScan = makeWineScan
        self.cellarWines = cellarWines
        self.onAddToCellar = onAddToCellar
        self.onRemoved = onRemoved
        self.onClose = onClose
        refresh()
    }

    /// How many bottles "Picks for [name]" shows (FRI-R11).
    static let giftLimit = 3

    public func load() async {
        if isTableSet { await lastTable.save([friend.id]) }
        if giftWines == nil {
            do {
                giftWines = try await buildTable.wines(for: friend.map, limit: Self.giftLimit)
            } catch {
                logger.error("Gift wines were not found: \(error.localizedDescription, privacy: .public)")
                giftWines = []
            }
        }
        guard bottles == nil else { return }
        await buildBottles()
    }

    public func selectTab(_ tab: FriendProfileTab) {
        self.tab = tab
    }

    // MARK: FRI-R13 · Set a table

    /// Builds the dinner chosen (again, if the choices changed since) and opens it in its sheet (FRI-R15a).
    public func setTable() async {
        isTableSet = true
        isTableOpen = true
        await lastTable.save([friend.id])
        guard preferences != builtFor || bottles == nil else { return }
        await buildBottles()
    }

    public func closeTable() {
        isTableOpen = false
        isSharing = false
    }

    // MARK: FRI-R13a · The dinner chosen

    public func toggleCourse(_ course: TableCourse) { preferences.toggle(course) }

    public func pickFood(_ food: DinnerPreferences.Food) { preferences.food = food }

    public func toggleInSeason() { preferences.inSeason.toggle() }

    public func pickTime(_ time: DinnerPreferences.Time) { preferences.time = time }

    private func buildBottles() async {
        let choice = preferences
        bottles = nil
        do {
            bottles = try await buildTable.execute(maps: [user.map, friend.map], preferences: choice)
        } catch {
            logger.error("Table was not built: \(error.localizedDescription, privacy: .public)")
            bottles = []
        }
        builtFor = choice
    }

    // MARK: FRI-R11a · Friend Wine

    public func openWine(_ id: String) { openedWine = .gift(id) }

    public func openTableWine(_ id: String) {
        openedWine = .table(id)
        readCellar()
    }

    public func closeWine() { openedWine = nil }

    // MARK: Add to cellar

    /// "Add to cellar" on a wine for the two: Friend Wine closes, then the Cellar's new note opens.
    public func addWineToCellar() {
        wineForCellar = openedWine.flatMap(wine)
        openedWine = nil
    }

    public func wineDismissed() {
        guard let wine = wineForCellar else { return }
        wineForCellar = nil
        onAddToCellar(wine)
    }

    /// The Cellar may have changed since the last wine (a note saved from here): read again as each wine opens.
    private func readCellar() {
        Task { cellarWineKeys = await cellarWines.wineKeys() }
    }

    // MARK: FRI-R11b · Send to [name]

    /// Sends the open wine to the friend; a failure says so and lets it be sent again.
    public func sendWine() async {
        guard let wine = openedWine.flatMap(wine), sending[wine.id] != .sending, sending[wine.id] != .sent else { return }
        sending[wine.id] = .sending
        do {
            try await shareWine.send(wine, from: user, to: friend.id)
            sending[wine.id] = .sent
        } catch {
            logger.error("Wine was not sent: \(error.localizedDescription, privacy: .public)")
            sending[wine.id] = .failed
        }
    }

    private func wine(_ opened: OpenedWine) -> Wine? {
        switch opened {
        case let .gift(id): giftWines?.first { $0.id == id }
        case let .table(id): bottles?.first { $0.wine.id == id }?.wine
        case let .scanned(wine): wine
        }
    }

    // MARK: FRI-R12a · Scan a wine

    public func scanWine() {
        guard let makeWineScan, scanner == nil else { return }
        scanner = makeWineScan { [weak self] wine in
            self?.scannedWine = wine
            self?.scanner = nil
        }
    }

    public func closeScanner() { scanner = nil }

    /// The scanner is gone: the wine it read opens in Friend Wine, against the two maps.
    public func scannerDismissed() {
        guard let wine = scannedWine else { return }
        scannedWine = nil
        openedWine = .scanned(wine)
        readCellar()
    }

    // MARK: D4 · Remover

    public func askToRemove() { isConfirmingRemoval = true }

    public func cancelRemoval() { isConfirmingRemoval = false }

    public func confirmRemoval() async {
        isConfirmingRemoval = false
        do {
            try await removeFriend.execute(userID: user.id, friendID: friend.id)
            onRemoved(friend.id)
        } catch {
            logger.error("Friend was not removed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: FRI-R21 · Partilhar

    public func openShare() { isSharing = true }

    public func closeShare() { isSharing = false }

    public func close() { onClose() }

    private func refresh() {
        var model = uiModel
        let builder = FriendProfilePresentationBuilder(friend: friend, userMap: user.map, userName: user.firstName,
                                                       bottles: bottles, giftWines: giftWines, resources: model.resources)
        builder.build(into: &model)
        model.friendWine = openedWine.flatMap { opened in
            wine(opened).map { wine in
                let isForBoth = if case .gift = opened { false } else { true }
                return builder.friendWine(wine, isForBoth: isForBoth, sending: sending[wine.id] ?? .idle,
                                          isInCellar: cellarWineKeys.contains(wine.id))
            }
        }
        model.scanner = scanner
        model.canScan = makeWineScan != nil
        model.tab = tab
        model.isTableOpen = isTableOpen
        model.dinner = builder.dinner(preferences, now: Date(), isStale: isTableSet && preferences != builtFor)
        model.isConfirmingRemoval = isConfirmingRemoval
        model.isSharing = isSharing && model.share != nil
        uiModel = model
    }
}
