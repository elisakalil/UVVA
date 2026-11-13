import Core
import Foundation
import SwiftData

/// `FriendsRepository` on the Personal store. CloudKit allows no unique attributes, so duplicates that arrive by
/// sync are removed here.
public actor FriendsStore: StoreActor, FriendsRepository {
    public nonisolated let executor: StoreExecutor

    public init(modelContainer: ModelContainer) {
        executor = StoreExecutor(modelContainer, label: "app.uvva.store.friends")
    }

    public func friends() throws -> [Friend] {
        var seen = Set<String>()
        return try modelContext.fetch(FetchDescriptor<FriendEntity>())
            .filter { seen.insert($0.friendID).inserted }
            .map(\.friend)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public func replaceFriends(_ friends: [Friend]) throws {
        let wanted = Dictionary(friends.map { ($0.id, $0) }) { first, _ in first }
        var kept = Set<String>()
        for entity in try modelContext.fetch(FetchDescriptor<FriendEntity>()) {
            if let friend = wanted[entity.friendID], kept.insert(entity.friendID).inserted {
                entity.update(from: friend)
            } else {
                modelContext.delete(entity)
            }
        }
        for (id, friend) in wanted where !kept.contains(id) { modelContext.insert(FriendEntity(friend)) }
        try modelContext.save()
    }

    public func declinedRequests() throws -> Set<String> {
        Set(try modelContext.fetch(FetchDescriptor<DeclinedRequestEntity>()).map(\.userID))
    }

    public func decline(_ userID: String) throws {
        guard try !declinedRequests().contains(userID) else { return }
        modelContext.insert(DeclinedRequestEntity(userID: userID, declinedAt: .now))
        try modelContext.save()
    }

    public func dismissedSuggestions() throws -> Set<String> {
        Set(try modelContext.fetch(FetchDescriptor<DismissedSuggestionEntity>()).map(\.userID))
    }

    public func dismissSuggestion(_ userID: String) throws {
        guard try !dismissedSuggestions().contains(userID) else { return }
        modelContext.insert(DismissedSuggestionEntity(userID: userID, dismissedAt: .now))
        try modelContext.save()
    }

    public func lastTable() throws -> [String]? {
        try modelContext.fetch(FetchDescriptor<LastTableEntity>())
            .max { $0.openedAt < $1.openedAt }?
            .friendIDs
    }

    public func saveLastTable(_ friendIDs: [String]) throws {
        for old in try modelContext.fetch(FetchDescriptor<LastTableEntity>()) { modelContext.delete(old) }
        modelContext.insert(LastTableEntity(friendIDs: friendIDs, openedAt: .now))
        try modelContext.save()
    }
}
