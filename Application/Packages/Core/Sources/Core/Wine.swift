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
    public var region: String?
    public var country: String?
    public var grapes: [String]
    public var alcohol: Double?
    /// The appellation and strength, "Vinho Verde DOC · 12.5% abv".
    public var classification: String
    public var profile: PalateMap
    public var pairings: [String]
    /// The dish UVVA pairs with it, when there is one (HOME-R06).
    public var dish: Dish?
    /// The aromas and flavours, "Violet, rose, iris." Nil when the wine has none on record.
    public var note: String?
    /// Serving temperature in °C.
    public var serving: ClosedRange<Int>?
    /// One line on what the region is known for, written ahead in the content.
    public var originInsight: String?
    /// One line on what the appellation means and guarantees.
    public var appellationInsight: String?
    /// The appellation says something about the wine's rank or style (a DOCG, a Grand Cru, Port), so the day's
    /// suggestion shows it; a plain origin label stays in the data only.
    public var hasNotableAppellation: Bool
    /// One line on what the serving temperature does to this kind of wine.
    public var howToServe: String?

    public var displayName: String { producer.isEmpty ? name : "\(name), \(producer)" }

    public init(id: String, name: String, producer: String = "", vintage: Int? = nil, type: String = "Red",
                origin: String, region: String? = nil, country: String? = nil, grapes: [String] = [],
                alcohol: Double? = nil, classification: String = "",
                profile: PalateMap, dish: Dish? = nil, note: String? = nil, serving: ClosedRange<Int>? = nil,
                originInsight: String? = nil, appellationInsight: String? = nil, hasNotableAppellation: Bool = false,
                howToServe: String? = nil, pairings: [String] = []) {
        self.id = id
        self.name = name
        self.producer = producer
        self.vintage = vintage
        self.type = type
        self.origin = origin
        self.region = region
        self.country = country
        self.grapes = grapes
        self.alcohol = alcohol
        self.classification = classification
        self.profile = profile
        self.pairings = pairings
        self.dish = dish
        self.note = note
        self.serving = serving
        self.originInsight = originInsight
        self.appellationInsight = appellationInsight
        self.hasNotableAppellation = hasNotableAppellation
        self.howToServe = howToServe
    }
}
