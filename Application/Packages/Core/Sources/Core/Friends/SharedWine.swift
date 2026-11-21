import Foundation

/// A wine sent to a friend (FRI-R11b) as the public database keeps it: one record per sender, friend and wine, so
/// sending the same wine again only moves it to the top. The friend is told by a push (FRI-R11c).
public struct SharedWineRecord: Identifiable, Equatable, Sendable {
    /// The record's name.
    public var id: String
    public var from: String
    /// "Marina": the sender's first name when it was sent, for the push and for a friend no longer cached.
    public var fromName: String
    public var to: String
    public var wineID: String
    public var wineName: String
    public var sentAt: Date
    /// The wine as the sender saw it, for a friend whose catalog does not have it (a label just scanned).
    public var snapshot: SharedWineSnapshot?

    public init(id: String, from: String, fromName: String, to: String, wineID: String, wineName: String,
                sentAt: Date, snapshot: SharedWineSnapshot?) {
        self.id = id
        self.from = from
        self.fromName = fromName
        self.to = to
        self.wineID = wineID
        self.wineName = wineName
        self.sentAt = sentAt
        self.snapshot = snapshot
    }
}

/// What a sent wine carries of the wine itself: enough to show it on a phone whose catalog does not have it.
public struct SharedWineSnapshot: Codable, Equatable, Sendable {
    public var name: String
    public var producer: String
    public var vintage: Int?
    public var type: String
    public var origin: String
    public var region: String?
    public var country: String?
    public var grapes: [String]
    public var profile: [PalateAxis: Double]
    public var pairings: [String]
    public var note: String?

    public init(_ wine: Wine) {
        name = wine.name
        producer = wine.producer
        vintage = wine.vintage
        type = wine.type
        origin = wine.origin
        region = wine.region
        country = wine.country
        grapes = wine.grapes
        profile = wine.profile.values
        pairings = wine.pairings
        note = wine.note
    }

    public func wine(id: String) -> Wine {
        Wine(id: id, name: name, producer: producer, vintage: vintage, type: type, origin: origin, region: region,
             country: country, grapes: grapes, profile: PalateMap(profile), note: note, pairings: pairings)
    }
}

/// Sending wines to friends (FRI-R11b, R11c), on the public database like the requests (`SocialService`).
public protocol WineSharingService: Sendable {
    /// Sends the wine from the user to a friend; the friend's push says "[fromName] sent you a wine: [name]".
    func sendWine(_ wine: Wine, from userID: String, fromName: String, to friendID: String) async throws
    /// The wines sent to the user, newest first.
    func sharedWines(to userID: String) async throws -> [SharedWineRecord]
    /// One sent wine, by its record's name: the one a push opens.
    func sharedWine(id: String) async throws -> SharedWineRecord?
    /// Asks the public database to push a notification for every wine sent to the user. Asking again is harmless.
    func subscribeToSharedWines(userID: String) async throws
}

/// The push of a wine sent (FRI-R11c): its subscription's id, by which the app knows a push is one, and its words,
/// in the app's own strings (`SHARED_WINE_ALERT`: "%1$@ sent you a wine: %2$@").
public enum SharedWinePush {
    public static let subscriptionPrefix = "shared-wines-"
    public static let alertKey = "SHARED_WINE_ALERT"
}
