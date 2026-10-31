import Core
import Foundation
import SwiftData
import Testing
@testable import Storage

struct ProfileStoreTests {
    let store: ProfileStore
    let profile = Profile(id: "u1", authProvider: .apple, authUserID: "apple-1", firstName: "Elisa", phone: "+351912345678")

    init() throws {
        store = ProfileStore(modelContainer: try AppStore.makeInMemoryContainer())
    }

    // MARK: ONB-R02a · Sessão

    @Test func ONB_R02a_beforeTheSession_thereIsNoProfile() async throws {
        #expect(try await store.currentProfile() == nil)
    }

    @Test func ONB_R02a_save_startsTheSession() async throws {
        try await store.save(profile)
        #expect(try await store.currentProfile() == profile)
    }

    @Test func save_twice_updatesTheSameProfile() async throws {
        try await store.save(profile)
        var renamed = profile
        renamed.firstName = "Lisa"
        try await store.save(renamed)
        #expect(try await store.currentProfile()?.firstName == "Lisa")
    }

    // MARK: ONB-R27 · Conta existente

    @Test func ONB_R27_findsTheProfileOfTheSignedInAccount() async throws {
        try await store.save(profile)
        #expect(try await store.profile(authUserID: "apple-1", waitingUpTo: .zero) == profile)
    }

    @Test func ONB_R27_unknownAccount_givesUpAfterTheTimeout() async throws {
        #expect(try await store.profile(authUserID: "someone-else", waitingUpTo: .milliseconds(10)) == nil)
    }

    // MARK: HOME-R33 · Tour visto

    @Test func HOME_R33_markTourSeen_addsItOnce() async throws {
        try await store.save(profile)
        try await store.markTourSeen("home")
        try await store.markTourSeen("home")
        #expect(try await store.currentProfile()?.seenTours == ["home"])
    }
}
