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
    /// What the catalog says of each appellation, by its folded name without the category ("douro", "chianti
    /// classico"), for a scanned wine of the same appellation (CELLAR-R30).
    public var appellationInsights: [String: AppellationInsight]
    /// The aromas a note may name, folded ("black cherry"), as the card writes them ("Black cherry")
    /// (`AromaVocabulary`).
    public var aromas: [String: String]
    /// Every producer of the catalog, folded, as the catalog writes it.
    public var producers: [String: String]

    public struct AppellationInsight: Equatable, Sendable {
        public var insight: String
        public var isNotable: Bool
        /// The appellation with its category, as every catalog wine of it writes it ("Vinho Regional Lisboa"); nil
        /// when the catalog writes it with no category ("Napa Valley").
        public var printed: String?

        public init(insight: String, isNotable: Bool, printed: String? = nil) {
            self.insight = insight
            self.isNotable = isNotable
            self.printed = printed
        }
    }

    public init(grapeTypes: [String: String] = [:], appellationRegions: [String: String] = [:],
                appellationTypes: [String: String] = [:], regionCountries: [String: String] = [:],
                countries: Set<String> = [], appellationInsights: [String: AppellationInsight] = [:],
                aromas: [String: String] = AromaVocabulary.common, producers: [String: String] = [:]) {
        self.grapeTypes = grapeTypes
        self.appellationRegions = appellationRegions
        self.appellationTypes = appellationTypes
        self.regionCountries = regionCountries
        self.countries = countries
        self.appellationInsights = appellationInsights
        self.aromas = aromas
        self.producers = producers
    }

    public init(wines: [Wine]) {
        var grapeTypes: [String: [String: Int]] = [:]
        var appellationRegions: [String: [String: Int]] = [:]
        var appellationTypes: [String: [String: Int]] = [:]
        var regionCountries: [String: [String: Int]] = [:]
        var countries = Set<String>()
        var insights: [String: AppellationInsight] = [:]
        // Each appellation as the catalog writes it, by category: "Tejo" is both a DOC and a Vinho Regional, so a
        // label that only says "Tejo" cannot be told apart, and the catalog's line on it may not be about this wine.
        var printed: [String: [String: String]] = [:]
        var producers: [String: String] = [:]
        for wine in wines {
            let producer = WineText.tokens(wine.producer).joined(separator: " ")
            if !producer.isEmpty, producers[producer] == nil { producers[producer] = wine.producer }
            if let appellation = wine.appellation, let insight = wine.appellationInsight, !insight.isEmpty {
                let key = Self.appellationKey(appellation)
                if !key.isEmpty {
                    if let category = CertificationKeywords.split(appellation).category,
                       printed[key]?[category] == nil {
                        printed[key, default: [:]][category] = appellation
                    }
                    if insights[key] == nil {
                        insights[key] = AppellationInsight(insight: insight, isNotable: wine.hasNotableAppellation)
                    }
                }
            }
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
        for (key, forms) in printed {
            if forms.count == 1 {
                insights[key]?.printed = forms.values.first
            } else if Set(forms.values.map { CertificationKeywords.split($0).tier }).count > 1 {
                insights[key] = nil
            }
        }
        self.init(grapeTypes: grapeTypes.mapValues(Self.mostCommon),
                  appellationRegions: appellationRegions.mapValues(Self.mostCommon),
                  appellationTypes: appellationTypes.mapValues(Self.mostCommon),
                  regionCountries: regionCountries.mapValues(Self.mostCommon),
                  countries: countries, appellationInsights: insights, producers: producers)
    }

    /// What the catalog says of this appellation, written with or without its category: "Douro DOC", "Douro".
    public func insight(for appellation: String) -> AppellationInsight? {
        appellationInsights[Self.appellationKey(appellation)]
    }

    /// The wine with what the catalog says of its appellation, when it says nothing of its own (CELLAR-R30). A label
    /// that names the place without its category ("Lisboa") takes the catalog's ("Vinho Regional Lisboa"), so the
    /// certificate ranks it as what it is.
    public func describingAppellation(of wine: Wine) -> Wine {
        guard wine.appellationInsight == nil, let appellation = wine.appellation,
              let known = insight(for: appellation) else { return wine }
        var described = wine
        if let printed = known.printed, CertificationKeywords.split(appellation).category == nil {
            described = described.settingAppellation(printed)
        }
        described.appellationInsight = known.insight
        described.hasNotableAppellation = described.hasNotableAppellation || known.isNotable
        return described
    }

    private static func appellationKey(_ appellation: String) -> String {
        WineText.tokens(CertificationKeywords.split(appellation).name ?? "").joined(separator: " ")
    }

    /// The commonest value; ties go to the first in alphabetical order, so the result never depends on the
    /// catalog's order.
    private static func mostCommon(_ counts: [String: Int]) -> String {
        counts.max { lhs, rhs in lhs.value == rhs.value ? lhs.key > rhs.key : lhs.value < rhs.value }?.key ?? ""
    }
}
