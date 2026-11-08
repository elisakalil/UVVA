import Foundation

/// What the Friends tab keeps in the Personal store (ARCHITECTURE §2.1). Friendship itself lives in the public
/// database (`SocialService`); the friends here are a cache, so the tab opens without network.
public protocol FriendsRepository: Sendable {
    /// The cached friends, by name.
    func friends() async throws -> [Friend]
    /// Replaces the cache after a refresh: friends not in the list are removed.
    func replaceFriends(_ friends: [Friend]) async throws

    /// Ids whose request the user declined. Kept here only, so the sender is not told (FRI-R08a).
    func declinedRequests() async throws -> Set<String>
    func decline(_ userID: String) async throws

    /// Ids taken out of Quick add with `×`; they are not suggested again (FRI-R09, D4).
    func dismissedSuggestions() async throws -> Set<String>
    func dismissSuggestion(_ userID: String) async throws

    /// The friends at the last table opened (FRI-R17); the table is worked out again when opened.
    func lastTable() async throws -> [String]?
    func saveLastTable(_ friendIDs: [String]) async throws
}
