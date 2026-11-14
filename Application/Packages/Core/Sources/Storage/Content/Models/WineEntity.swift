import Core
import Foundation
import SwiftData

/// A wine of the catalog, in the Content store (ARCHITECTURE §2.2).
@Model
public final class WineEntity {
    #Unique<WineEntity>([\.wineKey])
    #Index<WineEntity>([\.type], [\.country], [\.region], [\.source])

    public var wineKey: String
    public var name: String
    public var producer: String
    public var vintage: Int?
    public var origin: String
    public var region: String?
    public var country: String?
    public var grapes: [String]
    public var type: String
    public var alcohol: Double?
    public var servingMin: Int
    public var servingMax: Int
    public var pairings: [String]
    public var classification: String
    public var findIt: String
    public var note: String
    public var originInsight: String?
    public var appellationInsight: String?
    public var hasNotableAppellation: Bool = false
    public var howToServe: String?
    /// The legal term read on a scanned wine's label, "Grande Reserva" (CELLAR-R30).
    public var designation: String?
    /// The medals and scores read on a scanned wine's bottle, as `WineAward.text`.
    public var awards: [String] = []
    public var floral: Double
    public var body: Double
    public var tannin: Double
    public var spice: Double
    public var oak: Double
    public var sweetness: Double
    public var acidity: Double
    public var fruit: Double
    /// Where the wine came from: `catalog` (the public database), `scanned` (read on a label here and not in the
    /// catalog yet), or `bundle` (the catalog the app once shipped with, until the first snapshot replaces it).
    public var source: String

    init(wineKey: String, source: String) {
        self.wineKey = wineKey
        self.name = ""
        self.producer = ""
        self.origin = ""
        self.grapes = []
        self.type = ""
        self.servingMin = 0
        self.servingMax = 0
        self.pairings = []
        self.classification = ""
        self.findIt = ""
        self.note = ""
        self.floral = 0
        self.body = 0
        self.tannin = 0
        self.spice = 0
        self.oak = 0
        self.sweetness = 0
        self.acidity = 0
        self.fruit = 0
        self.source = source
    }

    static let catalogSource = "catalog"
    static let scannedSource = "scanned"
    static let bundleSource = "bundle"

    /// A wine of the public catalog, replaced from it or inserted. A scanned wine the catalog now has is the
    /// catalog's from here on. Not saved.
    @discardableResult
    static func upsert(_ data: CatalogWineData, existing: WineEntity?, in context: ModelContext) -> WineEntity {
        let entity = existing ?? WineEntity(wineKey: data.id, source: catalogSource)
        if existing == nil { context.insert(entity) }
        entity.source = catalogSource
        entity.update(from: data)
        return entity
    }

    func update(from data: CatalogWineData) {
        name = data.name
        producer = data.producer
        vintage = data.vintage
        origin = data.origin
        region = data.region
        country = data.country
        grapes = data.grapes
        type = data.type
        alcohol = data.alcohol
        // An unknown serving temperature stays min > max, which reads back as none.
        servingMin = data.servingTemperature?.min ?? 1
        servingMax = data.servingTemperature?.max ?? 0
        pairings = data.pairings
        classification = data.classification
        findIt = data.findIt ?? ""
        note = data.note ?? ""
        originInsight = data.originInsight
        appellationInsight = data.appellationInsight
        hasNotableAppellation = data.hasNotableAppellation ?? false
        howToServe = data.howToServe
        designation = data.designation
        awards = data.awards ?? []
        floral = data.map.floral
        body = data.map.body
        tannin = data.map.tannin
        spice = data.map.spice
        oak = data.map.oak
        sweetness = data.map.sweetness
        acidity = data.map.acidity
        fruit = data.map.fruit
    }

    public var palateMap: PalateMap {
        PalateMap([.floral: floral, .body: body, .tannin: tannin, .spice: spice,
                   .oak: oak, .sweetness: sweetness, .acidity: acidity, .fruit: fruit])
    }
}
