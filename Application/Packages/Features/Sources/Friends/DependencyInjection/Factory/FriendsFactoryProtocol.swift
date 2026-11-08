@MainActor
public protocol FriendsFactoryProtocol {
    func makeViewModel(onFriendsChange: @escaping () -> Void) -> FriendsViewModel
}
