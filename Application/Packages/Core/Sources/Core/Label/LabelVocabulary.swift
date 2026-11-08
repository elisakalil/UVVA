import Foundation

/// The names the parser looks for on a label, taken from the catalog: grapes, appellations, regions and countries
/// as the catalog spells them, so what is read can be matched against the catalog afterwards.
public struct LabelVocabulary: Sendable {
    /// Every grape, with the type most of its wines are.
    public var grapeTypes: [String: String]
    /// Every appellation (the first part of `origin`), with the region and the type most of its wines have.
    public var appellationRegions: [String: String]
    public var appellationTypes: [String: String]
    /// Every region, with its country.
    public var regionCountries: [String: String]
    public var countries: Set<String>

    public init(grapeTypes: [String: String] = [:], appellationRegions: [String: String] = [:],
                appellationTypes: [String: String] = [:], regionCountries: [String: String] = [:],
                countries: Set<String> = []) {
        self.grapeTypes = grapeTypes
        self.appellationRegions = appellationRegions
        self.appellationTypes = appellationTypes
        self.regionCountries = regionCountries
        self.countries = countries
    }

    public init(wines: [Wine]) {
        var grapeTypes: [String: [String: Int]] = [:]
        var appellationRegions: [String: [String: Int]] = [:]
        var appellationTypes: [String: [String: Int]] = [:]
        var regionCountries: [String: [String: Int]] = [:]
        var countries = Set<String>()
        for wine in wines {
            for grape in wine.grapes { grapeTypes[grape, default: [:]][wine.type, default: 0] += 1 }
            if let country = wine.country, !country.isEmpty {
                countries.insert(country)
                if let region = wine.region, !region.isEmpty {
                    regionCountries[region, default: [:]][country, default: 0] += 1
                }
            }
            let appellation = wine.origin.components(separatedBy: ",").first?
                .trimmingCharacters(in: .whitespaces) ?? ""
            if !appellation.isEmpty, appellation != wine.country {
                appellationTypes[appellation, default: [:]][wine.type, default: 0] += 1
                if let region = wine.region, !region.isEmpty {
                    appellationRegions[appellation, default: [:]][region, default: 0] += 1
                }
            }
        }
        self.init(grapeTypes: grapeTypes.mapValues(Self.mostCommon),
                  appellationRegions: appellationRegions.mapValues(Self.mostCommon),
                  appellationTypes: appellationTypes.mapValues(Self.mostCommon),
                  regionCountries: regionCountries.mapValues(Self.mostCommon),
                  countries: countries)
    }

    /// The commonest value; ties go to the first in alphabetical order, so the result never depends on the
    /// catalog's order.
    private static func mostCommon(_ counts: [String: Int]) -> String {
        counts.max { lhs, rhs in lhs.value == rhs.value ? lhs.key > rhs.key : lhs.value < rhs.value }?.key ?? ""
    }
}
