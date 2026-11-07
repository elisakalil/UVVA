import Core
import Foundation
import Synchronization
@testable import Onboarding

struct AuthStub: Authenticating {
    var identity: AuthIdentity?
    var fails = false

    func signIn() async throws -> AuthIdentity? {
        if fails { throw URLError(.notConnectedToInternet) }
        return identity
    }

    func isStillAuthorized(_ userID: String) async -> Bool { true }
}

final class ProfileRepositorySpy: ProfileRepository {
    private let profiles = Mutex<[Profile]>([])
    let failsToSave: Bool

    init(existing: [Profile] = [], failsToSave: Bool = false) {
        self.failsToSave = failsToSave
        profiles.withLock { $0 = existing }
    }

    var saved: [Profile] { profiles.withLock { $0 } }

    func currentProfile() async throws -> Profile? { saved.first }
    func profile(authUserID: String, waitingUpTo timeout: Duration) async throws -> Profile? {
        saved.first { $0.authUserID == authUserID }
    }
    func save(_ profile: Profile) async throws {
        if failsToSave { throw URLError(.cannotWriteToFile) }
        profiles.withLock { $0.append(profile) }
    }
    func markTourSeen(_ tour: String) async throws {}
    func deleteAccount() async throws {}
}

struct MapRepositoryStub: PalateMapRepository {
    var map: PalateMap?
    func currentMap() async throws -> PalateMap? { map }
    func saveQuizMap(_ map: PalateMap, at date: Date) async throws {}
    func history() async throws -> [MapChange] { [] }
    func saveRatedMap(_ map: PalateMap, wineKey: String, verdict: Verdict, at date: Date) async throws {}
}

final class SocialSpy: SocialService {
    private let state = Mutex<(keys: [String], requests: [String])>(([], []))
    let accounts: [String: PublicProfile]

    init(accounts: [String: PublicProfile] = [:]) { self.accounts = accounts }

    var publishedPhones: [String] { state.withLock { $0.keys } }
    var requests: [String] { state.withLock { $0.requests } }

    func publishContactKey(phone: String, userID: String) async throws -> Bool {
        state.withLock { $0.keys.append(phone) }
        return true
    }
    func accounts(forPhones phones: [String]) async throws -> [String: PublicProfile] {
        accounts.filter { phones.contains($0.key) }
    }
    func sendFriendRequest(from: String, to: String) async throws {
        state.withLock { $0.requests.append("\(from)->\(to)") }
    }
    func publish(_ profile: PublicProfile) async throws {}
    func removeContactKey(phone: String) async throws {}
    func deleteAccount(userID: String, phone: String?) async throws {}
}

struct CloudStub: CloudAccountStatus {
    var available = true
    func isAvailable() async -> Bool { available }
}

struct ContactsStub: ContactsProviding {
    var granted = true
    var contacts: [DeviceContact] = []
    func requestAccess() async -> Bool { granted }
    func fetch() async throws -> [DeviceContact] { contacts }
}
