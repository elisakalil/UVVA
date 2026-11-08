import Combine

@MainActor
public protocol FriendsViewModelProtocol: ObservableObject {
    associatedtype ProfileModel: FriendProfileViewModelProtocol
    associatedtype GroupTableModel: GroupTableViewModelProtocol
    var uiModel: FriendsUIModel { get }
    /// The friend open over the list (FRI-R10).
    var profile: ProfileModel? { get }
    func openFriend(_ id: String)
    func closeFriend()
    /// The group table open over the list (FRI-R19).
    var groupTable: GroupTableModel? { get }
    func startSelecting()
    func cancelSelecting()
    func toggle(_ id: String)
    func findBottle()
    func closeGroupTable()
    /// Every time the tab opens; the public database is read at most every `refreshInterval`.
    func load() async
    /// Pull to refresh: reads the public database now.
    func reload() async
    func accept(_ id: String) async
    func decline(_ id: String) async
    func add(_ id: String) async
    /// Tapping "Requested" (D11).
    func cancelRequest(_ id: String) async
    func dismissSuggestion(_ id: String) async
    func askForContacts() async
    func openInvite()
    func closeInvite()
}
