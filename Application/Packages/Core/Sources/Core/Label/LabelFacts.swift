import Foundation

/// The wine as read on its label (CELLAR-R17), before it is looked up in the catalog. Every field may be missing.
public struct LabelFacts: Equatable, Sendable {
    public var name: String?
    public var producer: String?
    public var vintage: Int?
    /// Red, White, Rosé, Sparkling or Fortified, as in the catalog.
    public var type: String?
    /// The appellation as the catalog writes it, "Chianti Classico".
    public var appellation: String?
    public var region: String?
    public var country: String?
    public var grapes: [String]
    /// % abv.
    public var alcohol: Double?
    /// The front lines that could be the name or the producer, biggest type first.
    public var titleLines: [String]

    public init(name: String? = nil, producer: String? = nil, vintage: Int? = nil, type: String? = nil,
                appellation: String? = nil, region: String? = nil, country: String? = nil, grapes: [String] = [],
                alcohol: Double? = nil, titleLines: [String] = []) {
        self.name = name
        self.producer = producer
        self.vintage = vintage
        self.type = type
        self.appellation = appellation
        self.region = region
        self.country = country
        self.grapes = grapes
        self.alcohol = alcohol
        self.titleLines = titleLines
    }

    /// Without a name there is nothing to save (CELLAR-R23).
    public var hasName: Bool { !(name ?? "").trimmingCharacters(in: .whitespaces).isEmpty }
}
