import Combine
import Core
import Foundation
import OSLog

/// The group table (FRI-R19): everyone's maps, the user's included, crossed into one table and its menu.
/// Opening it keeps it as the last table (FRI-R17).
@MainActor
public final class GroupTableViewModel: GroupTableViewModelProtocol {
    public nonisolated let id: String
    @Published public private(set) var uiModel = GroupTableUIModel()

    private var bottles: [TableBottle]? { didSet { refresh() } }
    private var isReadingsExpanded = false { didSet { refresh() } }
    private var isSharing = false { didSet { refresh() } }

    private let friends: [Friend]
    private let user: FriendsUser
    private let buildTable: any BuildTableUseCaseProtocol
    private let lastTable: any LastTableUseCaseProtocol
    private let onClose: () -> Void
    private let logger = Logger(subsystem: "app.uvva", category: "friends")

    init(friends: [Friend], user: FriendsUser, buildTable: any BuildTableUseCaseProtocol,
         lastTable: any LastTableUseCaseProtocol, onClose: @escaping () -> Void = {}) {
        id = friends.map(\.id).joined(separator: "+")
        self.friends = friends
        self.user = user
        self.buildTable = buildTable
        self.lastTable = lastTable
        self.onClose = onClose
        refresh()
    }

    public func load() async {
        await lastTable.save(friends.map(\.id))
        guard bottles == nil else { return }
        do {
            bottles = try await buildTable.execute(maps: [user.map] + friends.map(\.map))
        } catch {
            logger.error("Group table was not built: \(error.localizedDescription, privacy: .public)")
            bottles = []
        }
    }

    public func toggleReadings() { isReadingsExpanded.toggle() }

    public func openShare() { isSharing = true }

    public func closeShare() { isSharing = false }

    public func close() { onClose() }

    private func refresh() {
        var model = uiModel
        GroupTablePresentationBuilder(userMap: user.map, userName: user.firstName, friends: friends, bottles: bottles,
                                      resources: model.resources)
            .build(into: &model)
        model.isReadingsExpanded = isReadingsExpanded
        model.isSharing = isSharing && model.share != nil
        uiModel = model
    }
}
