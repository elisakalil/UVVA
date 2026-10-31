#if DEBUG
import Core
import Foundation

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
struct DemoSocial: SocialService {
    func publishContactKey(phone: String, userID: String) async throws -> Bool { true }

    func accounts(forPhones phones: [String]) async throws -> [String: PublicProfile] {
        let maps = [PalateMap([.acidity: 8, .fruit: 7, .floral: 6]), PalateMap([.tannin: 8, .oak: 7, .spice: 6])]
        var result: [String: PublicProfile] = [:]
        for (index, phone) in phones.sorted().prefix(2).enumerated() {
            result[phone] = PublicProfile(id: "demo-\(index)", firstName: "Friend", map: maps[index], hasMap: true)
        }
        return result
    }

    func sendFriendRequest(from: String, to: String) async throws {}
    func publish(_ profile: PublicProfile) async throws {}
}
#endif
