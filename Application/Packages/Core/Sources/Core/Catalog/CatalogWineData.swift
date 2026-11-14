import Foundation

/// One wine as the public catalog writes it (ARCHITECTURE §3.2, §4.1). The same JSON travels in every direction:
/// the robot reads it from `Data/UVVAWines.json` (once `pack_content.py` packs it), writes it in each `CatalogWine`
/// and in the snapshot, and the app sends it in each `WineContribution`. `id` is the wineKey.
public struct CatalogWineData: Codable, Equatable, Sendable {
    public struct Serving: Codable, Hashable, Sendable {
        public var min: Int
        public var max: Int

        public init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }
    }

    /// The eight axes, 0…9.
    public struct Axes: Codable, Equatable, Sendable {
        public var floral: Double
        public var body: Double
        public var tannin: Double
        public var spice: Double
        public var oak: Double
        public var sweetness: Double
        public var acidity: Double
        public var fruit: Double

        public init(_ map: PalateMap) {
            floral = map[.floral]
            body = map[.body]
            tannin = map[.tannin]
            spice = map[.spice]
            oak = map[.oak]
            sweetness = map[.sweetness]
            acidity = map[.acidity]
            fruit = map[.fruit]
        }

        public var palateMap: PalateMap {
            PalateMap([.floral: floral, .body: body, .tannin: tannin, .spice: spice,
                       .oak: oak, .sweetness: sweetness, .acidity: acidity, .fruit: fruit])
        }
    }

    public var id: String
    public var name: String
    public var producer: String
    public var vintage: Int?
    public var origin: String
    public var region: String?
    public var country: String?
    public var grapes: [String]
    public var type: String
    public var alcohol: Double?
    /// Nil when nobody knows it yet (a scanned wine).
    public var servingTemperature: Serving?
    public var pairings: [String]
    public var classification: String
    public var findIt: String?
    public var note: String?
    public var originInsight: String?
    public var appellationInsight: String?
    public var hasNotableAppellation: Bool?
    public var howToServe: String?
    public var designation: String?
    /// `WineAward.text` of each award.
    public var awards: [String]?
    public var map: Axes

    public init(_ wine: Wine, findIt: String? = nil) {
        id = wine.id
        name = wine.name
        producer = wine.producer
        vintage = wine.vintage
        origin = wine.origin
        region = wine.region
        country = wine.country
        grapes = wine.grapes
        type = wine.type
        alcohol = wine.alcohol
        servingTemperature = wine.serving.map { Serving(min: $0.lowerBound, max: $0.upperBound) }
        pairings = wine.pairings
        classification = wine.classification
        self.findIt = findIt
        note = wine.note
        originInsight = wine.originInsight
        appellationInsight = wine.appellationInsight
        hasNotableAppellation = wine.hasNotableAppellation
        howToServe = wine.howToServe
        designation = wine.designation
        awards = wine.awards.isEmpty ? nil : wine.awards.map(\.text)
        map = Axes(wine.profile)
    }

    public var wine: Wine {
        Wine(id: id, name: name, producer: producer, vintage: vintage, type: type, origin: origin, region: region,
             country: country, grapes: grapes, alcohol: alcohol, classification: classification,
             profile: map.palateMap, note: note?.isEmpty == false ? note : nil,
             serving: servingTemperature.flatMap { $0.min <= $0.max ? $0.min...$0.max : nil },
             originInsight: originInsight, appellationInsight: appellationInsight,
             hasNotableAppellation: hasNotableAppellation ?? false, howToServe: howToServe, pairings: pairings,
             designation: designation, awards: (awards ?? []).compactMap(WineAward.init(text:)))
    }

    /// The words a label of this wine is looked up by in the public catalog (`CatalogWine.tokens`): those of its
    /// name and producer, as `LabelMatch` compares them.
    public var searchTokens: [String] {
        Array(WineText.significantTokens(name).union(WineText.significantTokens(producer))).sorted()
    }
}

/// The catalog file: `{"wines": […]}`, in the snapshot and in what `pack_content.py --seed` writes.
public struct CatalogWinesFile: Codable, Sendable {
    public var wines: [CatalogWineData]

    public init(wines: [CatalogWineData]) {
        self.wines = wines
    }
}
