import Foundation

/// One wine of wines.json. `id` is the wineKey.
struct PackedWine: Decodable {
    var id: String
    var name: String
    var producer: String
    var vintage: Int?
    var origin: String
    var region: String?
    var country: String?
    var grapes: [String]
    var type: String
    var alcohol: Double?
    var servingTemperature: PackedServingTemperature
    var pairings: [String]
    var classification: String
    var findIt: String
    var note: String
    var map: PackedAxes
}
