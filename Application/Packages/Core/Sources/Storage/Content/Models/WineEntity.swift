import Core
import Foundation
import SwiftData

/// A wine of the catalog, in the Content store (ARCHITECTURE §2.2).
@Model
public final class WineEntity {
    #Unique<WineEntity>([\.wineKey])
    #Index<WineEntity>([\.type], [\.country], [\.region], [\.segment])

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
    public var floral: Double
    public var body: Double
    public var tannin: Double
    public var spice: Double
    public var oak: Double
    public var sweetness: Double
    public var acidity: Double
    public var fruit: Double
    /// Groups wines with similar maps for the catalog sync (MATCH.md, Segmento). Not computed yet.
    public var segment: Int?
    /// Where the wine came from: `bundle` or `catalog` (the public database).
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

    public var palateMap: PalateMap {
        PalateMap([.floral: floral, .body: body, .tannin: tannin, .spice: spice,
                   .oak: oak, .sweetness: sweetness, .acidity: acidity, .fruit: fruit])
    }
}
