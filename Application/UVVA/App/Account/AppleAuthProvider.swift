import AuthenticationServices
import Core
import Foundation

/// Sign in with Apple (ONB-R29). Apple sends the name only on the very first authorisation, so it is kept in
/// the Keychain until the account exists; otherwise a sign-up interrupted before the Phone step would lose it.
struct AppleAuthProvider: Authenticating {
    private let names = KeychainNameStore()

    func signIn() async throws -> AuthIdentity? {
        guard let credential = try await AppleSignInRequest().run() else { return nil }
        let userID = credential.user
        if let given = credential.fullName?.givenName, !given.isEmpty {
            names.save(given, for: userID)
        }
        return AuthIdentity(provider: .apple, userID: userID, givenName: names.name(for: userID))
    }

    /// Only a revoked credential ends the session; `notFound` also comes back offline.
    func isStillAuthorized(_ userID: String) async -> Bool {
        let state = try? await ASAuthorizationAppleIDProvider().credentialState(forUserID: userID)
        return state != .revoked
    }
}
