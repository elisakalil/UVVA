import Foundation

/// Reads and writes the account in the Personal store.
public protocol ProfileRepository: Sendable {
    func currentProfile() async throws -> Profile?
    /// The profile of `authUserID`, waiting up to `timeout` for iCloud to bring it to a new device (ONB-R27).
    func profile(authUserID: String, waitingUpTo timeout: Duration) async throws -> Profile?
    /// Starts the session (ONB-R02a).
    func save(_ profile: Profile) async throws
    /// HOME-R33
    func markTourSeen(_ tour: String) async throws
}
