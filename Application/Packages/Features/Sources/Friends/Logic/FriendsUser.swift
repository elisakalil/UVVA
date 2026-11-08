import Core
import Foundation

/// The user, as the Friends tab needs them: the id that names their requests, the map every compatibility is
/// read against, and what the invite shows.
struct FriendsUser: Equatable, Sendable {
    var id: String
    var firstName: String
    var map: PalateMap
    var inviteLink: URL
}
