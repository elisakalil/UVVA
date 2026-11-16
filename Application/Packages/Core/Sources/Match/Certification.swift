import Core
import Foundation

/// What certifies a wine (CELLAR-R30): its appellation and how high it ranks, the legal term on its label, the
/// medals and scores on the bottle, and the "Top X%" worked out from the three.
public struct WineCertificate: Equatable, Sendable {
    /// "Lisboa", without the category.
    public var appellation: String?
    /// The appellation as the wine writes it: "Vinho Regional Lisboa", "Douro DOC".
    public var printed: String?
    /// "Vinho Regional", "DOCG".
    public var category: String?
    public var tier: AppellationTier?
    /// One line on what the appellation means: the catalog's, or the category's.
    public var insight: String?
    /// "Grande Reserva".
    public var designation: String?
    public var designationStrength: DesignationStrength?
    /// One line on what the law makes of the term where the wine is from.
    public var designationNote: String?
    public var awards: [WineAward]
    /// 0 without awards, up to 4 for a trophy or 95 points.
    public var recognition: Int
    /// "Top 2%"; nil outside the top half.
    public var topPercent: Int?
    /// What the "Top X%" was worked out from: "DOCG", "Grande Reserva", "Gold · Decanter World Wine Awards · 2023".
    public var basis: [String]
}

public enum Certification {
    /// The wine's certificate; nil for a wine with no appellation the law protects, no legal term and no award, which
    /// shows no card.
    public static func make(for wine: Wine, prevalence: QualityPrevalence? = .current) -> WineCertificate? {
        let split = wine.appellation.map(CertificationKeywords.split)
        let tier = tier(of: wine)
        let designation = designation(of: wine)
        let strength = strength(of: wine)
        // Only medals a competition gave: what a reading took from camera noise is no award (CELLAR-R30).
        let awards = wine.awards.filter(\.isPlausible)
        let recognition = awards.map(level).max() ?? 0
        guard tier != nil || (strength ?? .weak) >= .aged || recognition > 0 else { return nil }

        let topPercent = prevalence.flatMap {
            QualityEstimate.topPercent(tier: tier, strength: strength, recognition: recognition, prevalence: $0)
        }
        var basis: [String] = []
        if let prevalence, prevalence.share(tier) < 0.95 {
            basis.append(split?.category ?? split?.name ?? "")
        }
        if let designation, let prevalence, prevalence.share(strength) < 0.95 { basis.append(designation) }
        if let best = awards.max(by: { level($0) < level($1) }), recognition > 0 { basis.append(best.text) }
        return WineCertificate(
            appellation: split?.name, printed: wine.appellation, category: split?.category, tier: tier,
            insight: wine.appellationInsight ?? split?.category.flatMap { categoryInsights[$0] },
            designation: designation, designationStrength: strength,
            designationNote: designation.flatMap { note(for: $0, strength: strength, country: wine.country) },
            awards: awards, recognition: recognition, topPercent: topPercent,
            basis: basis.filter { !$0.isEmpty })
    }

    /// How high the wine's appellation ranks. An appellation the catalog writes with no category but describes
    /// ("Napa Valley") is a protected origin, as `pack_content.py` counts it. A scanned "Lisboa" never gets there:
    /// `LabelVocabulary` gives it its category.
    static func tier(of wine: Wine) -> AppellationTier? {
        var tier = wine.appellation.map(CertificationKeywords.split)?.tier
        if tier == nil, wine.appellation != nil, wine.appellationInsight != nil { tier = .protected }
        if wine.appellation != nil, wine.hasNotableAppellation { tier = .top }
        return tier
    }

    static func designation(of wine: Wine) -> String? {
        wine.designation ?? CertificationKeywords.designation(in: wine.name)
    }

    static func strength(of wine: Wine) -> DesignationStrength? {
        designation(of: wine).flatMap { CertificationKeywords.strength(of: $0, country: wine.country) }
    }

    /// 4: trophy, platinum or double gold at a major competition, or 95+ points; 3: gold at a major competition, or
    /// 92–94; 2: silver at a major competition, gold elsewhere, or 90–91; 1: any other.
    static func level(_ award: WineAward) -> Int {
        let source = CertificationKeywords.source(in: award.competition)
        if let points = award.points {
            guard source != nil else { return 1 }
            switch points {
            case 95...: return 4
            case 92...94: return 3
            case 90...91: return 2
            default: return 1
            }
        }
        let major = source?.tier == .major
        switch award.medal {
        case .trophy, .platinum, .doubleGold: return major ? 4 : 2
        case .gold: return major ? 3 : (source != nil ? 2 : 1)
        case .silver: return major ? 2 : 1
        default: return 1
        }
    }

    // MARK: Lines

    static let categoryInsights: [String: String] = {
        let regional = "A regional wine: a protected origin with broader rules than a DOC, which leave the producer more freedom."
        let cru = "Ranked among the leading estates of its region in an official classification."
        return [
            "DOCG": "Italy's highest classification: a guaranteed origin, stricter rules and a tasting panel's approval.",
            "DOCa": "Spain's highest classification, held only by Rioja and Priorat.",
            "DOQ": "Spain's highest classification, held only by Rioja and Priorat.",
            "Grand Cru": "One of the finest vineyards of its region, at the top of its ladder.",
            "Grand Cru Classé": cru, "Premier Grand Cru Classé": cru, "Cru Classé": cru,
            "Premier Cru": "A vineyard ranked just below Grand Cru in its region.",
            "Grosse Lage": "The top class of vineyard of Germany's VDP growers.",
            "DOC": "A protected origin with its own rules for grapes, yields and ageing.",
            "DOP": "A protected origin under European rules, with its own rules for grapes and yields.",
            "DO": "Spain's protected origin label, with rules for grapes and yields.",
            "AOC": "France's protected origin label: grapes, yields and methods follow the appellation's rules.",
            "AOP": "France's protected origin label: grapes, yields and methods follow the appellation's rules.",
            "AVA": "An American Viticultural Area: a defined growing region, with no rules on grapes or methods.",
            "DAC": "Austria's origin label for wines typical of their area.",
            "VQA": "Canada's quality label: grapes from the named area, checked by a tasting panel.",
            "WO": "South Africa's Wine of Origin: the grapes come from the named area.",
            "Prädikatswein": "Germany's top quality level, graded by how ripe the grapes were.",
            "Qualitätswein": "German quality wine from one of its thirteen regions.",
            "IGT": regional, "IGP": regional, "IG": regional, "Vinho Regional": regional, "Vin de Pays": regional,
            "Vino de la Tierra": regional, "Landwein": regional
        ]
    }()

    static func note(for designation: String, strength: DesignationStrength?, country: String?) -> String? {
        switch (designation, country, strength) {
        case ("Grande Reserva", "Portugal", .strong?):
            "In Portugal: approved by tasting, for outstanding wines."
        case ("Gran Reserva", "Spain", .strong?):
            "In Spain: 5 years of ageing, 18 months in oak."
        case ("Riserva", "Italy", .strong?):
            "In Italy: longer ageing than the standard wine."
        case ("Reserva", "Portugal", .aged?):
            "In Portugal: approved by tasting."
        case ("Reserva", "Spain", .aged?):
            "In Spain: 3 years of ageing, 1 in oak."
        case ("Crianza", "Spain", .aged?):
            "In Spain: 2 years of ageing, 6 months in oak."
        case (_, _, .weak?):
            "Not defined by law here: the producer's own term."
        default:
            nil
        }
    }
}
