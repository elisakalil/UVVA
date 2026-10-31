import Foundation

/// The public side of friends (ARCHITECTURE §3.2, §4.4).
public protocol SocialService: Sendable {
    /// Publishes the contact key of a phone. False when another account already holds it (ONB-R07a).
    func publishContactKey(phone: String, userID: String) async throws -> Bool
    /// The accounts behind these phones (E.164), keyed by phone.
    func accounts(forPhones phones: [String]) async throws -> [String: PublicProfile]
    func sendFriendRequest(from: String, to: String) async throws
    func publish(_ profile: PublicProfile) async throws
}
