import Core

@MainActor
protocol RefreshFriendsUseCaseProtocol {
    /// The friends kept on the device, without network.
    func cached() async -> [Friend]
    /// Reads the requests and the friends' maps from the public database, and keeps the friends on the device.
    func execute(userID: String) async throws -> FriendsSnapshot
}
