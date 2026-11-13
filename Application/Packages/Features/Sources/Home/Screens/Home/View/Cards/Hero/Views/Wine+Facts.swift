import Core
import Foundation

/// The facts of a wine as the day's suggestion shows them.
extension Wine {
    /// "Tuscany, Italy"; the packed origin when the region is missing.
    var originLine: String {
        guard let region, !region.isEmpty else { return origin }
        guard let country, !country.isEmpty, country != region else { return region }
        return "\(region), \(country)"
    }
}
