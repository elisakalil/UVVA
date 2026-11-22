import Core
import Foundation

/// The facts of a wine as the day's suggestion shows them.
extension Wine {
    /// "Tuscany, Italy"; the packed origin when the region is missing.
    var originLine: String {
        let resources = HomeResourcesUIModel()
        guard let country, !country.isEmpty else {
            return region.flatMap { $0.isEmpty ? nil : $0 } ?? resources.wineFilterLabel(origin)
        }
        let displayCountry = resources.wineFilterLabel(country)
        guard let region, !region.isEmpty else {
            if origin == country || origin.isEmpty { return displayCountry }
            let suffix = ", \(country)"
            return origin.hasSuffix(suffix) ? String(origin.dropLast(suffix.count)) + ", " + displayCountry : origin
        }
        return region == country ? displayCountry : "\(region), \(displayCountry)"
    }
}
