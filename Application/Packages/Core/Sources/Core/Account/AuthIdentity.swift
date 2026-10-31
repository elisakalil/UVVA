import Foundation

/// Who signed in: the provider's stable user id and the first name it gave, if any (ONB-R14a).
public struct AuthIdentity: Equatable, Sendable {
    public var provider: AuthProvider
    public var userID: String
    public var givenName: String?

    public init(provider: AuthProvider, userID: String, givenName: String?) {
        self.provider = provider
        self.userID = userID
        self.givenName = givenName
    }
}
