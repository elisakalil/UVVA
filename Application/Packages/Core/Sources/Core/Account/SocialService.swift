import Foundation

/// The public side of friends (ARCHITECTURE §3.2, §4.4).
public protocol SocialService: Sendable {
    /// Publishes the contact key of a phone. False when another account already holds it (ONB-R07a).
    func publishContactKey(phone: String, userID: String) async throws -> Bool
    /// The accounts behind these phones (E.164), keyed by phone.
    func accounts(forPhones phones: [String]) async throws -> [String: PublicProfile]
    /// Creates the request `<from>-<to>`. Accepting a request is sending one back (PLANO-FRIENDS §2).
    func sendFriendRequest(from: String, to: String) async throws
    /// Requests made to this user.
    func friendRequests(to userID: String) async throws -> [FriendRequestRecord]
    /// Requests made by this user.
    func friendRequests(from userID: String) async throws -> [FriendRequestRecord]
    /// Takes back a request: cancelling it (D11) or removing a friend (D4). One already gone counts as deleted.
    func deleteFriendRequest(from: String, to: String) async throws
    /// The public profiles of these accounts, keyed by id. Accounts that no longer exist are left out.
    func profiles(ids: [String]) async throws -> [String: PublicProfile]
    func publish(_ profile: PublicProfile) async throws
    /// Takes a phone's contact key back, when the number changes or is removed (YOU-R15).
    func removeContactKey(phone: String) async throws
    /// YOU-R27: removes the public profile, the contact key and the friend requests the account made.
    func deleteAccount(userID: String, phone: String?) async throws
}
