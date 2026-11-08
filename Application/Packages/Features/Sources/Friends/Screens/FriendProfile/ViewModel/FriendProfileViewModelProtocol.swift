import Combine

@MainActor
public protocol FriendProfileViewModelProtocol: ObservableObject, Identifiable {
    var uiModel: FriendProfileUIModel { get }
    func load() async
    func selectTab(_ tab: FriendProfileTab)
    func askToRemove()
    func cancelRemoval()
    func confirmRemoval() async
    func openShare()
    func closeShare()
    func close()
}
