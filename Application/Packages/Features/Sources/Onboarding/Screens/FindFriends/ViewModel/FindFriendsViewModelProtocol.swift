import Combine
import Core

@MainActor
protocol FindFriendsViewModelProtocol: ObservableObject {
    var uiModel: FindFriendsUIModel { get }
    func findFriends() async
}
