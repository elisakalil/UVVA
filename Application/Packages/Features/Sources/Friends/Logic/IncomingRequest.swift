import Core
import Foundation

/// A friend request to the user, with who sent it (FRI-R08a).
struct IncomingRequest: Identifiable, Equatable, Sendable {
    var id: String
    var name: String
    var map: PalateMap
    var sentAt: Date
}
