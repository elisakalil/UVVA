import Core
import Foundation
import SwiftData
import Testing
@testable import Storage

struct FriendsStoreTests {
    let store: FriendsStore
    let marina = Friend(id: "marina", name: "Marina", map: PalateMap([.acidity: 7]), addedAt: Date(timeIntervalSince1970: 10))
    let bia = Friend(id: "bia", name: "Bia", map: PalateMap([.tannin: 6]), addedAt: Date(timeIntervalSince1970: 20))

    init() throws {
        store = FriendsStore(modelContainer: try AppStore.makeInMemoryContainer())
    }

    // MARK: Cache dos amigos

    @Test func noFriends_atFirst() async throws {
        #expect(try await store.friends().isEmpty)
    }

    @Test func FRI_R04_friends_byName_withTheirMaps() async throws {
        try await store.replaceFriends([marina, bia])
        #expect(try await store.friends() == [bia, marina])
    }

    @Test func replace_updatesAndRemoves() async throws {
        try await store.replaceFriends([marina, bia])
        var moved = marina
        moved.map = PalateMap([.acidity: 3, .fruit: 8])
        try await store.replaceFriends([moved])
        #expect(try await store.friends() == [moved])
    }

    @Test func replace_withTheSameFriendTwice_keepsOne() async throws {
        try await store.replaceFriends([marina, marina])
        #expect(try await store.friends().count == 1)
    }

    // MARK: FRI-R08a · Recusar

    @Test func FRI_R08a_decline_isKept_once() async throws {
        try await store.decline("marina")
        try await store.decline("marina")
        #expect(try await store.declinedRequests() == ["marina"])
    }

    // MARK: FRI-R09 · ×

    @Test func FRI_R09_dismissedSuggestion_isKept() async throws {
        try await store.dismissSuggestion("sofia")
        #expect(try await store.dismissedSuggestions() == ["sofia"])
    }

    // MARK: FRI-R17 · Última mesa

    @Test func FRI_R17_lastTable_isTheLastSaved() async throws {
        #expect(try await store.lastTable() == nil)
        try await store.saveLastTable(["marina"])
        try await store.saveLastTable(["bia", "rui"])
        #expect(try await store.lastTable() == ["bia", "rui"])
    }
}
