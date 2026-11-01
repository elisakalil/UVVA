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

struct AccountDeletionTests {
    @Test func YOU_R27_deleteAccount_removesProfileMapReminderAndCellar() async throws {
        let container = try AppStore.makeInMemoryContainer()
        let profiles = ProfileStore(modelContainer: container)
        try await profiles.save(Profile(id: "u1", authProvider: .apple, authUserID: "a1", firstName: "Elisa", phone: nil))
        try await PalateMapStore(modelContainer: container).saveQuizMap(PalateMap([.acidity: 6]), at: .now)
        try await ReminderStore(modelContainer: container).save(Reminder(hour: 19, weekdays: [2]))
        try await CellarStore(modelContainer: container)
            .addWantToTry(Wine(id: "w1", name: "W", origin: "", profile: PalateMap([:])))

        try await profiles.deleteAccount()

        #expect(try await profiles.currentProfile() == nil)
        #expect(try await PalateMapStore(modelContainer: container).currentMap() == nil)
        #expect(try await ReminderStore(modelContainer: container).reminder() == nil)
        #expect(try await CellarStore(modelContainer: container).wineKeys().isEmpty)
    }

    @Test func YOU_R27_sameAppleAccountAfterDeletion_isANewAccount() async throws {
        let profiles = ProfileStore(modelContainer: try AppStore.makeInMemoryContainer())
        try await profiles.save(Profile(id: "u1", authProvider: .apple, authUserID: "a1", firstName: "Elisa", phone: nil))
        try await profiles.deleteAccount()
        #expect(try await profiles.profile(authUserID: "a1", waitingUpTo: .zero) == nil)
    }
}

struct ReminderStoreTests {
    @Test func YOU_R18_R19_saveAndTurnOff() async throws {
        let store = ReminderStore(modelContainer: try AppStore.makeInMemoryContainer())
        try await store.save(Reminder(hour: 19, weekdays: [2, 4, 6]))
        #expect(try await store.reminder() == Reminder(hour: 19, weekdays: [2, 4, 6]))
        try await store.save(Reminder(hour: 8, minute: 30, weekdays: [1]))
        #expect(try await store.reminder()?.time == "08:30")
        try await store.save(nil)
        #expect(try await store.reminder() == nil)
    }

    @Test func profilePhoto_isKept() async throws {
        let profiles = ProfileStore(modelContainer: try AppStore.makeInMemoryContainer())
        try await profiles.save(Profile(id: "u1", authProvider: .apple, authUserID: "a1", firstName: "Elisa", phone: nil,
                                        photo: Data([1, 2, 3])))
        #expect(try await profiles.currentProfile()?.photo == Data([1, 2, 3]))
    }

    @Test func YOU_R07_firstPathModule() async throws {
        let container = try AppStore.makeInMemoryContainer()
        _ = try await ContentImporter(modelContainer: container)
            .importIfNeeded(from: ContentSource(directory: try ContentFixture().write()), currentVersion: nil)
        let module = try await CatalogStore(modelContainer: container).firstPathModule()
        #expect(module == CourseSummary(id: "path-01", title: "What Wine Is", lessonCount: 2, minutes: 15))
    }
}
