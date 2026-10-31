import Foundation

/// Runs the provider's sign-in sheet.
public protocol Authenticating: Sendable {
    /// Nil when the person closed the sheet (ONB-R38).
    func signIn() async throws -> AuthIdentity?
    /// False once the person revoked UVVA in their Apple ID settings.
    func isStillAuthorized(_ userID: String) async -> Bool
}
