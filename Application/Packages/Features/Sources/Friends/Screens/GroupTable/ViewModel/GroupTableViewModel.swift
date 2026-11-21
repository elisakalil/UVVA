import Combine
import Core
import CoreUI
import Foundation
import OSLog

/// The group table (FRI-R19): everyone's maps, the user's included, crossed into one table. As on a friend, the
/// dinner is set from its foot and opens in its own sheet (FRI-R15a), a bottle or a scanned wine opens Friend Wine,
/// read on every map at the table, to send to them all. Opening it keeps it as the last table (FRI-R17).
@MainActor
public final class GroupTableViewModel: GroupTableViewModelProtocol {
    public nonisolated let id: String
    @Published public private(set) var uiModel = GroupTableUIModel()

    private var bottles: [TableBottle]? { didSet { refresh() } }
    private var isReadingsExpanded = false { didSet { refresh() } }
    private var isSharing = false { didSet { refresh() } }
    /// FRI-R13: "Set the perfect dinner" was tapped at least once.
    private var isTableSet = false { didSet { refresh() } }
    /// FRI-R15a: the table's sheet is open.
    private var isTableOpen = false { didSet { refresh() } }
    /// FRI-R13a: the dinner the user chose, and the one the bottles were built for.
    private var preferences = DinnerPreferences() { didSet { refresh() } }
    private var builtFor = DinnerPreferences() { didSet { refresh() } }
    /// The wine open in Friend Wine: a bottle of "Open this together" or one just scanned.
    private var openedWine: OpenedWine? { didSet { refresh() } }
    /// FRI-R11b: how far each wine's sending got, by wine.
    private var sending: [String: FriendWinePresentationBuilder.Sending] = [:] { didSet { refresh() } }
    /// The friends each wine already reached, so that sending again after a failure only sends to the rest.
    private var reached: [String: Set<String>] = [:]
    /// FRI-R12a: the label scanner, while it is open, and the wine it read, until it is gone.
    private var scanner: NewNoteViewModel? { didSet { refresh() } }
    private var scannedWine: Wine?

    private enum OpenedWine {
        /// A bottle of "Open this together".
        case table(String)
        /// A wine just scanned.
        case scanned(Wine)
    }

    private let friends: [Friend]
    private let user: FriendsUser
    private let buildTable: any BuildTableUseCaseProtocol
    private let lastTable: any LastTableUseCaseProtocol
    private let shareWine: any ShareWineUseCaseProtocol
    private let makeWineScan: ((@escaping (Wine) -> Void) -> NewNoteViewModel)?
    private let onClose: () -> Void
    private let logger = Logger(subsystem: "app.uvva", category: "friends")

    init(friends: [Friend], user: FriendsUser, buildTable: any BuildTableUseCaseProtocol,
         lastTable: any LastTableUseCaseProtocol,
         shareWine: any ShareWineUseCaseProtocol = ShareWineUseCase(sharing: nil, wines: nil),
         makeWineScan: ((@escaping (Wine) -> Void) -> NewNoteViewModel)? = nil,
         onClose: @escaping () -> Void = {}) {
        id = friends.map(\.id).joined(separator: "+")
        self.friends = friends
        self.user = user
        self.buildTable = buildTable
        self.lastTable = lastTable
        self.shareWine = shareWine
        self.makeWineScan = makeWineScan
        self.onClose = onClose
        refresh()
    }

    private var tableIDs: [String] { friends.map(\.id) }

    public func load() async {
        await lastTable.save(tableIDs)
        guard bottles == nil else { return }
        await buildBottles()
    }

    public func toggleReadings() { isReadingsExpanded.toggle() }

    // MARK: FRI-R13 · Set a table

    /// Builds the dinner chosen (again, if the choices changed since) and opens it in its sheet (FRI-R15a).
    public func setTable() async {
        isTableSet = true
        isTableOpen = true
        await lastTable.save(tableIDs)
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
            bottles = try await buildTable.execute(maps: [user.map] + friends.map(\.map), preferences: choice)
        } catch {
            logger.error("Group table was not built: \(error.localizedDescription, privacy: .public)")
            bottles = []
        }
        builtFor = choice
    }

    // MARK: Friend Wine

    public func openTableWine(_ id: String) { openedWine = .table(id) }

    public func closeWine() { openedWine = nil }

    /// Sends the open wine to everyone at the table; a failure says so and lets it be sent again, to those it did
    /// not reach.
    public func sendWine() async {
        guard let wine = openedWine.flatMap(wine), sending[wine.id] != .sending, sending[wine.id] != .sent else { return }
        sending[wine.id] = .sending
        var failed = false
        for friend in friends where reached[wine.id, default: []].contains(friend.id) == false {
            do {
                try await shareWine.send(wine, from: user, to: friend.id)
                reached[wine.id, default: []].insert(friend.id)
            } catch {
                logger.error("Wine was not sent: \(error.localizedDescription, privacy: .public)")
                failed = true
            }
        }
        sending[wine.id] = failed ? .failed : .sent
    }

    private func wine(_ opened: OpenedWine) -> Wine? {
        switch opened {
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

    /// The scanner is gone: the wine it read opens in Friend Wine, against every map at the table.
    public func scannerDismissed() {
        guard let wine = scannedWine else { return }
        scannedWine = nil
        openedWine = .scanned(wine)
    }

    // MARK: FRI-R21 · Partilhar

    public func openShare() { isSharing = true }

    public func closeShare() { isSharing = false }

    public func close() { onClose() }

    private func refresh() {
        var model = uiModel
        let builder = GroupTablePresentationBuilder(userMap: user.map, userName: user.firstName, friends: friends,
                                                    bottles: bottles, resources: model.resources)
        builder.build(into: &model)
        model.friendWine = openedWine.flatMap(wine).map { builder.friendWine($0, sending: sending[$0.id] ?? .idle) }
        model.scanner = scanner
        model.canScan = makeWineScan != nil
        model.isReadingsExpanded = isReadingsExpanded
        model.isTableOpen = isTableOpen
        model.dinner = builder.dinner(preferences, now: Date(), isStale: isTableSet && preferences != builtFor)
        model.isSharing = isSharing && model.share != nil
        uiModel = model
    }
}
