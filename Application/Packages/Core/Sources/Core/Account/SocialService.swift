import Foundation

/// The public side of friends (ARCHITECTURE §3.2, §4.4).
public protocol SocialService: Sendable {
    /// Publishes the contact key of a phone. False when another account already holds it (ONB-R07a).
    func publishContactKey(phone: String, userID: String) async throws -> Bool
    /// The accounts behind these phones (E.164), keyed by phone.
    func accounts(forPhones phones: [String]) async throws -> [String: PublicProfile]
    func sendFriendRequest(from: String, to: String) async throws
    func publish(_ profile: PublicProfile) async throws
    /// Takes a phone's contact key back, when the number changes or is removed (YOU-R15).
    func removeContactKey(phone: String) async throws
    /// YOU-R27: removes the public profile and the contact key of an account.
    func deleteAccount(userID: String, phone: String?) async throws
}
