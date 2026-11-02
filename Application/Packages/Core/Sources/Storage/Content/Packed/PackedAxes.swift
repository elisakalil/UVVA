import Foundation

/// The eight axes of a wine or recipe, as packed ("map": {"floral": 6.2, …}).
struct PackedAxes: Decodable {
    var floral: Double
    var body: Double
    var tannin: Double
    var spice: Double
    var oak: Double
    var sweetness: Double
    var acidity: Double
    var fruit: Double
}
