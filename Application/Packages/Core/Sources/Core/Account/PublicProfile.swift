import Foundation

/// What other people can see of an account (ARCHITECTURE §3.2): the name and, when public, the map.
public struct PublicProfile: Equatable, Sendable {
    public var id: String
    public var firstName: String
    /// Nil when the map is not public.
    public var map: PalateMap?
    public var hasMap: Bool

    public init(id: String, firstName: String, map: PalateMap?, hasMap: Bool) {
        self.id = id
        self.firstName = firstName
        self.map = map
        self.hasMap = hasMap
    }
}
