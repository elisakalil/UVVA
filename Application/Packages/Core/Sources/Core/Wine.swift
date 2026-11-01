import Foundation

public struct Wine: Identifiable, Equatable, Sendable {
    /// The wineKey (ARCHITECTURE §2.2).
    public var id: String
    public var name: String
    public var producer: String
    /// Nil for wines without a vintage, which show no year.
    public var vintage: Int?
    /// Red, White, Rosé, Sparkling or Fortified.
    public var type: String
    public var origin: String
    public var grapes: [String]
    public var alcohol: Double?
    /// The appellation and strength, "Vinho Verde DOC · 12.5% abv".
    public var classification: String
    public var profile: PalateMap
    /// The dish UVVA pairs with it, when there is one (HOME-R06).
    public var dish: Dish?
    /// One or two lines on how it tastes, shown on the Home cards.
    public var note: String?
    /// Serving temperature in °C.
    public var serving: ClosedRange<Int>?
    
    public var displayName: String { producer.isEmpty ? name : "\(name), \(producer)" }

    public init(id: String, name: String, producer: String = "", vintage: Int? = nil, type: String = "Red",
                origin: String, grapes: [String] = [], alcohol: Double? = nil, classification: String = "",
                profile: PalateMap, dish: Dish? = nil, note: String? = nil, serving: ClosedRange<Int>? = nil) {
        self.id = id
        self.name = name
        self.producer = producer
        self.vintage = vintage
        self.type = type
        self.origin = origin
        self.grapes = grapes
        self.alcohol = alcohol
        self.classification = classification
        self.profile = profile
        self.dish = dish
        self.note = note
        self.serving = serving
    }
}
