import Foundation

/// A friend request as the public database keeps it (ARCHITECTURE §3.2): one record per direction, named
/// `<from>-<to>`. Only its creator can change it, so nobody edits the other side's request (PLANO-FRIENDS §2).
public struct FriendRequestRecord: Hashable, Sendable {
    public var from: String
    public var to: String
    public var createdAt: Date

    public init(from: String, to: String, createdAt: Date) {
        self.from = from
        self.to = to
        self.createdAt = createdAt
    }
}
