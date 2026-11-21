import Core

@MainActor
protocol LoadNotificationsUseCaseProtocol {
    /// The requests and wines friends sent, and the notifications already read. Without a network, or without the
    /// public database, only what was read: the rest of the list comes from the Home's own data.
    func sources() async -> HomeNotificationSources
    /// HOME-R04: a notification is read once the user opens it.
    func markRead(_ id: String) async
}
