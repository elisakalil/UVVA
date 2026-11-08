import Foundation

/// Who is a friend, who asked and who is waiting, read from the requests in both directions (PLANO-FRIENDS §2).
/// Two people are friends when each one has a request to the other: accepting is sending the request back
/// (FRI-R08a), and two crossed requests are a friendship with nothing to accept (FRI-R08b).
public struct Friendship: Equatable, Sendable {
    /// Friends, with the date the second request was made.
    public var friends: [String: Date]
    /// Requests to the user that are not answered and were not declined (FRI-R08a).
    public var incoming: [FriendRequestRecord]
    /// The user's requests still waiting ("Requested", FRI-R08).
    public var outgoing: [FriendRequestRecord]
    /// The user's requests to people who were friends and took theirs back (removed, D4). The app deletes these
    /// so the friendship does not come back as a request.
    public var lapsed: [FriendRequestRecord]

    public init(friends: [String: Date] = [:], incoming: [FriendRequestRecord] = [],
                outgoing: [FriendRequestRecord] = [], lapsed: [FriendRequestRecord] = []) {
        self.friends = friends
        self.incoming = incoming
        self.outgoing = outgoing
        self.lapsed = lapsed
    }

    /// - Parameters:
    ///   - user: the user's id.
    ///   - sent: requests from the user; any other is ignored.
    ///   - received: requests to the user; any other is ignored.
    ///   - declined: ids whose request the user declined (kept on the device only, so the sender is not told).
    ///   - knownFriends: the friends from the last refresh, to tell a removal from a new request.
    public static func resolve(user: String, sent: [FriendRequestRecord], received: [FriendRequestRecord],
                               declined: Set<String> = [], knownFriends: Set<String> = []) -> Friendship {
        let sentTo = Dictionary(sent.filter { $0.from == user && $0.to != user }.map { ($0.to, $0) }) { first, _ in first }
        let receivedFrom = Dictionary(received.filter { $0.to == user && $0.from != user }.map { ($0.from, $0) }) { first, _ in first }

        var result = Friendship()
        for (id, mine) in sentTo {
            if let theirs = receivedFrom[id] {
                result.friends[id] = max(mine.createdAt, theirs.createdAt)
            } else if knownFriends.contains(id) {
                result.lapsed.append(mine)
            } else {
                result.outgoing.append(mine)
            }
        }
        for (id, theirs) in receivedFrom where sentTo[id] == nil && !declined.contains(id) {
            result.incoming.append(theirs)
        }
        result.incoming.sort { $0.createdAt > $1.createdAt }
        result.outgoing.sort { $0.createdAt > $1.createdAt }
        result.lapsed.sort { $0.to < $1.to }
        return result
    }
}
