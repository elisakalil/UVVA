import Foundation

/// A friend: both sides asked (FRI-R08a, R08b), so both see each other's map. Every friend has one (FRI-R01).
/// The compatibility is not kept here: it depends on the user's map and comes from `TableMatch` (Match).
public struct Friend: Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var map: PalateMap
    /// When the second request was made, that is, when the two became friends.
    public var addedAt: Date

    public init(id: String, name: String, map: PalateMap, addedAt: Date) {
        self.id = id
        self.name = name
        self.map = map
        self.addedAt = addedAt
    }
}
