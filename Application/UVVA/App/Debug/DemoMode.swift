#if DEBUG
import Core
import Foundation
import Synchronization

/// `-UVVADemoAccount` (Debug builds only): a fake Apple account, iCloud taken as signed in and two contacts
/// shown as on UVVA, so the Onboarding can be walked through in the simulator without an Apple ID.
enum DemoMode {
    static var isOn: Bool { ProcessInfo.processInfo.arguments.contains("-UVVADemoAccount") }
}

struct DemoAuth: Authenticating {
    func signIn() async throws -> AuthIdentity? {
        try await Task.sleep(for: .milliseconds(400))
        return AuthIdentity(provider: .apple, userID: "demo-apple-user", givenName: "Elisa")
    }

    func isStillAuthorized(_ userID: String) async -> Bool { true }
}

struct DemoCloud: CloudAccountStatus {
    func isAvailable() async -> Bool { true }
}

/// The first two phones asked about belong to accounts with a map; nothing is sent anywhere.
/// Friends: Marina is a friend, Bia asked the user, the user asked Rui; requests sent here are kept in memory.
final class DemoSocial: SocialService {
    private let sent = Mutex<[FriendRequestRecord]>([])
    private let since = Date(timeIntervalSinceNow: -86_400 * 3)

    private let demoProfiles: [String: PublicProfile] = [
        "demo-marina": PublicProfile(id: "demo-marina", firstName: "Marina",
                                     map: PalateMap([.acidity: 7, .fruit: 6.5, .body: 5, .floral: 4]), hasMap: true),
        "demo-bia": PublicProfile(id: "demo-bia", firstName: "Bia",
                                  map: PalateMap([.tannin: 7, .oak: 6, .body: 6, .fruit: 5]), hasMap: true),
        "demo-rui": PublicProfile(id: "demo-rui", firstName: "Rui",
                                  map: PalateMap([.spice: 7, .fruit: 6, .sweetness: 3, .acidity: 5]), hasMap: true)
    ]

    func publishContactKey(phone: String, userID: String) async throws -> Bool { true }

    func accounts(forPhones phones: [String]) async throws -> [String: PublicProfile] {
        let maps = [PalateMap([.acidity: 8, .fruit: 7, .floral: 6]), PalateMap([.tannin: 8, .oak: 7, .spice: 6])]
        var result: [String: PublicProfile] = [:]
        for (index, phone) in phones.sorted().prefix(2).enumerated() {
            result[phone] = PublicProfile(id: "demo-\(index)", firstName: "Friend", map: maps[index], hasMap: true)
        }
        return result
    }

    func sendFriendRequest(from: String, to: String) async throws {
        sent.withLock { list in
            if !list.contains(where: { $0.from == from && $0.to == to }) {
                list.append(FriendRequestRecord(from: from, to: to, createdAt: .now))
            }
        }
    }

    func friendRequests(to userID: String) async throws -> [FriendRequestRecord] {
        ["demo-marina", "demo-bia"].map { FriendRequestRecord(from: $0, to: userID, createdAt: since) }
    }

    func friendRequests(from userID: String) async throws -> [FriendRequestRecord] {
        let seeded = ["demo-marina", "demo-rui"].map { FriendRequestRecord(from: userID, to: $0, createdAt: since) }
        let extra = sent.withLock { $0 }.filter { $0.from == userID && !["demo-marina", "demo-rui"].contains($0.to) }
        return seeded + extra
    }

    func deleteFriendRequest(from: String, to: String) async throws {
        sent.withLock { $0.removeAll { $0.from == from && $0.to == to } }
    }

    func profiles(ids: [String]) async throws -> [String: PublicProfile] { demoProfiles.filter { ids.contains($0.key) } }

    func publish(_ profile: PublicProfile) async throws {}
    func removeContactKey(phone: String) async throws {}
    func deleteAccount(userID: String, phone: String?) async throws {}
}
#endif
