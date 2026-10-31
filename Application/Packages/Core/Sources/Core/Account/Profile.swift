import Foundation

/// The account (ARCHITECTURE §2.1). `id` is a UUID made at sign-up: it names the person in invite links and
/// friend requests, and does not depend on Apple or iCloud.
public struct Profile: Equatable, Sendable {
    public var id: String
    public var authProvider: AuthProvider
    public var authUserID: String
    public var firstName: String
    /// E.164
    public var phone: String?
    public var mapIsPublic: Bool
    public var seenTours: Set<String>
    /// JPEG of the profile photo (YOU-R14).
    public var photo: Data?

    public init(id: String, authProvider: AuthProvider, authUserID: String, firstName: String, phone: String?,
                mapIsPublic: Bool = true, seenTours: Set<String> = [], photo: Data? = nil) {
        self.id = id
        self.authProvider = authProvider
        self.authUserID = authUserID
        self.firstName = firstName
        self.phone = phone
        self.mapIsPublic = mapIsPublic
        self.seenTours = seenTours
        self.photo = photo
    }

    public var inviteLink: URL { URL(string: "https://uvva.app/invite/\(id)")! }
}
