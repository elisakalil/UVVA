import Core
import Foundation

/// FRI-R17: the last table opened is the one the Home's match card opens (HOME-R11).
@MainActor
struct LastTableUseCase: LastTableUseCaseProtocol {
    let friends: any FriendsRepository

    func load() async -> [String]? { try? await friends.lastTable() }

    func save(_ friendIDs: [String]) async { try? await friends.saveLastTable(friendIDs) }
}
