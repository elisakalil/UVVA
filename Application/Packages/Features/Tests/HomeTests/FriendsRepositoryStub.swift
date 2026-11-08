import Core
import Foundation

/// The friends the Friends tab keeps on the device (HOME-R11).
struct FriendsRepositoryStub: FriendsRepository {
    var list: [Friend] = []
    func friends() async throws -> [Friend] { list }
    func replaceFriends(_ friends: [Friend]) async throws {}
    func declinedRequests() async throws -> Set<String> { [] }
    func decline(_ userID: String) async throws {}
    func dismissedSuggestions() async throws -> Set<String> { [] }
    func dismissSuggestion(_ userID: String) async throws {}
    func lastTable() async throws -> [String]? { nil }
    func saveLastTable(_ friendIDs: [String]) async throws {}
}
