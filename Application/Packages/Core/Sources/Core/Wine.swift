import Foundation

public struct Wine: Identifiable, Equatable, Sendable {
    /// The wineKey (ARCHITECTURE §2.2).
    public var id: String
    public var name: String
    public var origin: String
    public var profile: PalateMap
    public var dish: Dish?
    /// One or two lines on how it tastes, shown on the Home cards.
    public var note: String?

    public init(id: String, name: String, origin: String, profile: PalateMap, dish: Dish? = nil, note: String? = nil) {
        self.id = id
        self.name = name
        self.origin = origin
        self.profile = profile
        self.dish = dish
        self.note = note
    }
}
