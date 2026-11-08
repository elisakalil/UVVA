import Core
import Foundation
import SwiftData

/// A friend, cached from the public profile (ARCHITECTURE §2.1, `Friend`). CloudKit: defaults everywhere, nothing
/// unique; the store keeps one per `friendID`.
@Model
public final class FriendEntity {
    public var friendID = ""
    public var name = ""
    /// `[PalateAxis: Double]` as JSON.
    var valuesData = Data()
    public var addedAt = Date.distantPast

    init(_ friend: Friend) {
        friendID = friend.id
        update(from: friend)
    }

    func update(from friend: Friend) {
        name = friend.name
        valuesData = (try? JSONEncoder().encode(friend.map.values)) ?? Data()
        addedAt = friend.addedAt
    }

    var friend: Friend {
        Friend(id: friendID, name: name,
               map: PalateMap((try? JSONDecoder().decode([PalateAxis: Double].self, from: valuesData)) ?? [:]),
               addedAt: addedAt)
    }
}
