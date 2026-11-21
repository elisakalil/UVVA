import Core

@MainActor
protocol ShareWineUseCaseProtocol {
    /// False when the app gave no way to send wines: the button does not show.
    var isAvailable: Bool { get }
    /// FRI-R11b: sends the wine to the friend, who is told by a push.
    func send(_ wine: Wine, from user: FriendsUser, to friendID: String) async throws
    /// FRI-R11c: the wines friends sent the user, newest first; one whose wine cannot be found is left out.
    func received(userID: String) async -> [ReceivedWine]
    /// The wine a push opens, by its record.
    func received(id: String) async -> ReceivedWine?
}
