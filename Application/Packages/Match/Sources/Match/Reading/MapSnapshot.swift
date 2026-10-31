import Core
import Foundation

/// The map at one moment of "Over time" (YOU-R10).
public struct MapSnapshot: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        /// The Quiz map.
        case first
        /// The map at the end of a month with ratings.
        case endOfMonth
        case today
    }

    public var kind: Kind
    public var date: Date
    public var map: PalateMap
    /// Wines rated up to this moment.
    public var winesRated: Int

    public init(kind: Kind, date: Date, map: PalateMap, winesRated: Int) {
        self.kind = kind
        self.date = date
        self.map = map
        self.winesRated = winesRated
    }
}
