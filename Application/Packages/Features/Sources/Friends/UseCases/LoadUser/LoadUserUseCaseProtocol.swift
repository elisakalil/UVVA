@MainActor
protocol LoadUserUseCaseProtocol {
    func execute() async throws -> FriendsUser?
}
