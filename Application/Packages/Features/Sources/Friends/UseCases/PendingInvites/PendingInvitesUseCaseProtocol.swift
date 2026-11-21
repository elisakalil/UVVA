import Core

@MainActor
protocol PendingInvitesUseCaseProtocol {
    /// The contacts the user invited who are not on UVVA yet, by name (FRI-R04b).
    func execute() async -> [InvitedContact]
}
