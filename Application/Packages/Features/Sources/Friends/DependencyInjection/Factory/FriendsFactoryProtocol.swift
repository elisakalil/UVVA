import Core

@MainActor
public protocol FriendsFactoryProtocol {
    func makeViewModel(onFriendsChange: @escaping () -> Void, onAddFriends: @escaping () -> Void,
                       onAddToCellar: @escaping (Wine) -> Void, onHasFriends: @escaping () -> Void) -> FriendsViewModel
}
