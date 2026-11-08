import Combine
import Core
import Foundation
import OSLog

/// A friend (FRIENDS.md §5): Palate, Compatibility and Table. Opening the Table keeps it as the last table (FRI-R17).
@MainActor
public final class FriendProfileViewModel: FriendProfileViewModelProtocol {
    public nonisolated let id: String
    @Published public private(set) var uiModel = FriendProfileUIModel()

    private var tab: FriendProfileTab { didSet { refresh() } }
    private var bottles: [TableBottle]? { didSet { refresh() } }
    private var isConfirmingRemoval = false { didSet { refresh() } }
    private var isSharing = false { didSet { refresh() } }

    private let friend: Friend
    private let user: FriendsUser
    private let buildTable: any BuildTableUseCaseProtocol
    private let lastTable: any LastTableUseCaseProtocol
    private let removeFriend: any RemoveFriendUseCaseProtocol
    private let onRemoved: (String) -> Void
    private let onClose: () -> Void
    private let logger = Logger(subsystem: "app.uvva", category: "friends")

    init(friend: Friend, user: FriendsUser, tab: FriendProfileTab = .palate,
         buildTable: any BuildTableUseCaseProtocol, lastTable: any LastTableUseCaseProtocol,
         removeFriend: any RemoveFriendUseCaseProtocol,
         onRemoved: @escaping (String) -> Void = { _ in }, onClose: @escaping () -> Void = {}) {
        id = friend.id
        self.friend = friend
        self.user = user
        self.tab = tab
        self.buildTable = buildTable
        self.lastTable = lastTable
        self.removeFriend = removeFriend
        self.onRemoved = onRemoved
        self.onClose = onClose
        refresh()
    }

    public func load() async {
        if tab == .table { await lastTable.save([friend.id]) }
        guard bottles == nil else { return }
        do {
            bottles = try await buildTable.execute(maps: [user.map, friend.map])
        } catch {
            logger.error("Table was not built: \(error.localizedDescription, privacy: .public)")
            bottles = []
        }
    }

    public func selectTab(_ tab: FriendProfileTab) {
        self.tab = tab
        if tab == .table { Task { await lastTable.save([friend.id]) } }
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
        FriendProfilePresentationBuilder(friend: friend, userMap: user.map, userName: user.firstName, bottles: bottles,
                                         resources: model.resources)
            .build(into: &model)
        model.tab = tab
        model.isConfirmingRemoval = isConfirmingRemoval
        model.isSharing = isSharing && model.share != nil
        uiModel = model
    }
}
