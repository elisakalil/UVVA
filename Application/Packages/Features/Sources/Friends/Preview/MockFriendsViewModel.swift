#if DEBUG
import Combine
import Foundation

/// The Friends tab with fixed rows, for previews.
final class MockFriendsViewModel: FriendsViewModelProtocol {
    @Published private(set) var uiModel = FriendsUIModel()
    @Published private(set) var profile: MockFriendProfileViewModel?
    @Published private(set) var groupTable: MockGroupTableViewModel?

    init(empty: Bool = false) {
        var model = FriendsUIModel()
        model.isLoading = false
        model.isReady = true
        model.quickAdd = .suggestions([
            QuickAddRowUIModel(id: "sofia", name: "Sofia Reis", signature: "FLORAL · FRUIT · ACIDITY", isRequested: false),
            QuickAddRowUIModel(id: "joao", name: "João Lima", signature: "TANNIN · OAK · BODY", isRequested: true)
        ])
        if empty {
            model.isEmpty = true
        } else {
            model.countText = "3 friends"
            model.canSelect = true
            model.requests = [FriendRequestRowUIModel(id: "ana", name: "Ana", signature: "SPICE · FRUIT · BODY")]
            model.friends = [
                FriendRowUIModel(id: "bia", name: "Bia Damas", signature: "TANNIN · OAK · BODY", compatibilityText: "74%"),
                FriendRowUIModel(id: "marina", name: "Marina Alves", signature: "ACIDITY · FRUIT · BODY", compatibilityText: "82%"),
                FriendRowUIModel(id: "rui", name: "Rui das Neves", signature: "SPICE · FRUIT · SWEETNESS", compatibilityText: "61%")
            ]
        }
        uiModel = model
    }

    func openFriend(_ id: String) { profile = MockFriendProfileViewModel() }
    func closeFriend() { profile = nil }
    func startSelecting() {
        var model = uiModel
        model.isSelecting = true
        model.selectButtonText = "Pick at least two friends"
        uiModel = model
    }
    func cancelSelecting() {
        var model = uiModel
        model.isSelecting = false
        model.selectedIDs = []
        uiModel = model
    }
    func toggle(_ id: String) {
        var model = uiModel
        if model.selectedIDs.contains(id) { model.selectedIDs.remove(id) } else { model.selectedIDs.insert(id) }
        model.canFindBottle = model.selectedIDs.count >= 2
        model.selectButtonText = model.canFindBottle ? "Find a bottle for these \(model.selectedIDs.count)" : "Pick at least two friends"
        uiModel = model
    }
    func findBottle() { groupTable = MockGroupTableViewModel() }
    func closeGroupTable() { groupTable = nil }
    func load() async {}
    func reload() async {}
    func accept(_ id: String) async {}
    func decline(_ id: String) async {}
    func add(_ id: String) async {}
    func cancelRequest(_ id: String) async {}
    func dismissSuggestion(_ id: String) async {}
    func askForContacts() async {}
    func openInvite() {}
    func closeInvite() {}
}
#endif
