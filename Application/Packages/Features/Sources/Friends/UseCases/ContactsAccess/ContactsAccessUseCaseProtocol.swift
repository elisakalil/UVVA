import Core

@MainActor
protocol ContactsAccessUseCaseProtocol {
    func current() -> ContactsAccess
    /// Shows the iOS prompt when it can; returns the access after it.
    func request() async -> ContactsAccess
}
