import Core
import Foundation
import Synchronization

struct ProfilesStub: ProfileRepository {
    var profile: Profile? = Profile(id: "elisa", authProvider: .apple, authUserID: "apple", firstName: "Elisa", phone: nil)
    func currentProfile() async throws -> Profile? { profile }
    func profile(authUserID: String, waitingUpTo timeout: Duration) async throws -> Profile? { profile }
    func save(_ profile: Profile) async throws {}
    func markTourSeen(_ tour: String) async throws {}
    func deleteAccount() async throws {}
}

struct MapStub: PalateMapRepository {
    var map: PalateMap? = PalateMap([.acidity: 7, .fruit: 6])
    func currentMap() async throws -> PalateMap? { map }
    func saveQuizMap(_ map: PalateMap, at date: Date) async throws {}
    func history() async throws -> [MapChange] { [] }
    func saveRatedMap(_ map: PalateMap, wineKey: String, verdict: Verdict, at date: Date) async throws {}
}

/// The public database in memory: requests and profiles, like CloudKit keeps them.
final class SocialFake: SocialService {
    struct State {
        var requests: [FriendRequestRecord] = []
        var profiles: [String: PublicProfile] = [:]
        var phones: [String: String] = [:]
        var failsWriting = false
    }
    let state = Mutex(State())

    func profile(_ id: String, _ name: String, map: PalateMap? = PalateMap([.acidity: 7, .fruit: 6]), phone: String? = nil) {
        state.withLock {
            $0.profiles[id] = PublicProfile(id: id, firstName: name, map: map, hasMap: map != nil)
            if let phone { $0.phones[phone] = id }
        }
    }

    func request(_ from: String, _ to: String, at date: Date = Date(timeIntervalSince1970: 0)) {
        state.withLock { $0.requests.append(FriendRequestRecord(from: from, to: to, createdAt: date)) }
    }

    var requests: [FriendRequestRecord] { state.withLock { $0.requests } }
    func failWrites() { state.withLock { $0.failsWriting = true } }

    func publishContactKey(phone: String, userID: String) async throws -> Bool { true }
    func accounts(forPhones phones: [String]) async throws -> [String: PublicProfile] {
        state.withLock { state in
            Dictionary(uniqueKeysWithValues: phones.compactMap { phone in
                state.phones[phone].flatMap { state.profiles[$0] }.map { (phone, $0) }
            })
        }
    }
    func sendFriendRequest(from: String, to: String) async throws {
        try state.withLock {
            if $0.failsWriting { throw URLError(.notConnectedToInternet) }
            if !$0.requests.contains(where: { $0.from == from && $0.to == to }) {
                $0.requests.append(FriendRequestRecord(from: from, to: to, createdAt: .now))
            }
        }
    }
    func friendRequests(to userID: String) async throws -> [FriendRequestRecord] { requests.filter { $0.to == userID } }
    func friendRequests(from userID: String) async throws -> [FriendRequestRecord] { requests.filter { $0.from == userID } }
    func deleteFriendRequest(from: String, to: String) async throws {
        try state.withLock {
            if $0.failsWriting { throw URLError(.notConnectedToInternet) }
            $0.requests.removeAll { $0.from == from && $0.to == to }
        }
    }
    func profiles(ids: [String]) async throws -> [String: PublicProfile] {
        state.withLock { $0.profiles.filter { ids.contains($0.key) } }
    }
    func publish(_ profile: PublicProfile) async throws {}
    func removeContactKey(phone: String) async throws {}
    func deleteAccount(userID: String, phone: String?) async throws {}
}

final class FriendsRepositoryFake: FriendsRepository {
    struct State {
        var friends: [Friend] = []
        var declined: Set<String> = []
        var dismissed: Set<String> = []
        var lastTable: [String]?
    }
    let state = Mutex(State())

    func friends() async throws -> [Friend] { state.withLock { $0.friends } }
    func replaceFriends(_ friends: [Friend]) async throws { state.withLock { $0.friends = friends } }
    func declinedRequests() async throws -> Set<String> { state.withLock { $0.declined } }
    func decline(_ userID: String) async throws { state.withLock { _ = $0.declined.insert(userID) } }
    func dismissedSuggestions() async throws -> Set<String> { state.withLock { $0.dismissed } }
    func dismissSuggestion(_ userID: String) async throws { state.withLock { _ = $0.dismissed.insert(userID) } }
    func lastTable() async throws -> [String]? { state.withLock { $0.lastTable } }
    func saveLastTable(_ friendIDs: [String]) async throws { state.withLock { $0.lastTable = friendIDs } }
}

final class ContactsFake: ContactsProviding {
    let state: Mutex<(access: ContactsAccess, grantOnRequest: Bool, contacts: [DeviceContact])>

    init(access: ContactsAccess = .granted, grantOnRequest: Bool = true, contacts: [DeviceContact] = []) {
        state = Mutex((access, grantOnRequest, contacts))
    }

    func access() -> ContactsAccess { state.withLock { $0.access } }
    func requestAccess() async -> Bool {
        state.withLock {
            if $0.access == .notDetermined { $0.access = $0.grantOnRequest ? .granted : .denied }
            return $0.access == .granted
        }
    }
    func fetch() async throws -> [DeviceContact] { state.withLock { $0.contacts } }
}

/// One wine and one dish per course, so every table has three bottles.
struct CatalogStub: CatalogRepository {
    static let wines = [
        Wine(id: "white", name: "Alvarinho", producer: "Soalheiro", type: "White", origin: "", profile: PalateMap([.acidity: 8, .fruit: 6])),
        Wine(id: "red", name: "Chianti", producer: "Isole e Olena", type: "Red", origin: "", profile: PalateMap([.acidity: 6, .fruit: 7])),
        Wine(id: "port", name: "Tawny", producer: "Graham's", type: "Fortified", origin: "", profile: PalateMap([.sweetness: 8, .fruit: 7]))
    ]
    static let recipes = [
        Recipe(id: "sardines", title: "Grilled sardines", why: "", course: "starter", wineTypes: ["White"], profile: PalateMap([.acidity: 7])),
        Recipe(id: "risotto", title: "Mushroom risotto", why: "", course: "main", wineTypes: ["Red"], profile: PalateMap([.fruit: 6])),
        Recipe(id: "nata", title: "Pastel de nata", why: "", course: "dessert", wineTypes: ["Fortified"], profile: PalateMap([.sweetness: 7]))
    ]
    func winesClosest(to map: PalateMap, limit: Int) async throws -> [Wine] { Self.wines }
    func recipes() async throws -> [Recipe] { Self.recipes }
    func glossary() async throws -> [GlossaryTerm] { [] }
    func firstPathModule() async throws -> CourseSummary? { nil }
}
