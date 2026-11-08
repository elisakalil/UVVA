@MainActor
protocol RemoveFriendUseCaseProtocol {
    func execute(userID: String, friendID: String) async throws
}
