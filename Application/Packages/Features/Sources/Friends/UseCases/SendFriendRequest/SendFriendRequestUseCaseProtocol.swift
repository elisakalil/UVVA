@MainActor
protocol SendFriendRequestUseCaseProtocol {
    func execute(from userID: String, to friendID: String) async throws
}
