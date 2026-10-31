import Core
import Foundation
import SwiftData

/// The account, in the Personal store (ARCHITECTURE §2.1). Synced with CloudKit: defaults everywhere, nothing unique.
@Model
public final class ProfileEntity {
    /// A UUID made at sign-up.
    public var id = ""
    public var authProvider = AuthProvider.apple.rawValue
    public var authUserID = ""
    public var firstName = ""
    /// E.164
    public var phone: String?
    public var mapIsPublic = true
    public var seenTours: [String] = []
    public var language = "en"
    public var createdAt = Date.distantPast

    init(_ profile: Profile, createdAt: Date) {
        self.createdAt = createdAt
        update(from: profile)
    }

    func update(from profile: Profile) {
        id = profile.id
        authProvider = profile.authProvider.rawValue
        authUserID = profile.authUserID
        firstName = profile.firstName
        phone = profile.phone
        mapIsPublic = profile.mapIsPublic
        seenTours = profile.seenTours.sorted()
    }

    public var profile: Profile {
        Profile(id: id, authProvider: AuthProvider(rawValue: authProvider) ?? .apple, authUserID: authUserID,
                firstName: firstName, phone: phone, mapIsPublic: mapIsPublic, seenTours: Set(seenTours))
    }
}
