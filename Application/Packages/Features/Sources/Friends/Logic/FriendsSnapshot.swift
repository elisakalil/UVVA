import Core
import Foundation

/// The friends side of the public database after a refresh (PLANO-FRIENDS §2).
struct FriendsSnapshot: Equatable, Sendable {
    var friends: [Friend] = []
    var incoming: [IncomingRequest] = []
    /// Ids the user asked and who did not answer yet ("Requested", FRI-R08).
    var requested: Set<String> = []
}
