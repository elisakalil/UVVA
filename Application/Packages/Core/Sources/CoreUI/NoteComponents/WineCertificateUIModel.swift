import Core
import Foundation
import Match

/// The certificate card of a wine (CELLAR-R30), in WineDetail, the new note and a saved note. Closed, two lines: "Among
/// the top X% of the world's wines" with the seal when the wine is in the top 20 %, or else a title on its appellation,
/// and under it what it rests on. Open, one section per criterion: the appellation, the legal term and the awards.
public struct WineCertificateUIModel: Equatable {
    public struct Section: Equatable, Identifiable {
        /// "Appellation", in small capitals.
        public var title: String
        /// "Vinho Regional Lisboa · Regional, free to experiment".
        public var value: String?
        /// What it means, one paragraph each.
        public var lines: [String]
        public var id: String { title }

        public init(title: String, value: String? = nil, lines: [String] = []) {
            self.title = title
            self.value = value
            self.lines = lines
        }
    }

    /// "Top 2% of the world's wines", or "Regional, free to experiment".
    public var headline: String
    /// "Regional, free to experiment · Lisboa · Grande Reserva".
    public var subline: String?
    public var sections: [Section]
    /// The seal, only for an appellation at the top of its country's ladder (DOCG, Grand Cru…).
    public var showsSeal = false
    public var moreText = String(localized: "More", bundle: .module)
    public var lessText = String(localized: "Less", bundle: .module)

    public init(headline: String, subline: String? = nil, sections: [Section] = [], showsSeal: Bool = false) {
        self.headline = headline
        self.subline = subline
        self.sections = sections
        self.showsSeal = showsSeal
    }

    /// Nil for a wine with nothing that certifies it: the card is not shown.
    public init?(wine: Wine, prevalence: QualityPrevalence? = .current) {
        guard let certificate = Certification.make(for: wine, prevalence: prevalence) else { return nil }
        self.init(certificate, prevalence: prevalence)
    }

    /// A saved note's card: the "Top X%" it was saved with (`CellarEntry.certificateTop`), not one worked out again.
    /// It is worked out again from what the wine shows now when none was kept (0: saved while only the top 10 % had
    /// one, or outside the top) or when the kept one may rest on camera noise (an award that is no award).
    public init?(wine: Wine, keptTop: Int) {
        guard var certificate = Certification.make(for: wine) else { return nil }
        let restedOnNoise = wine.awards.contains { !AwardEvidence.isPlausible($0) }
        if keptTop > 0, certificate.topPercent != nil, !restedOnNoise {
            certificate.topPercent = keptTop
        }
        self.init(certificate)
    }

    /// A wine in the top 20 % shows the seal, "Among the top 2% of the world's wines" and what puts it there; open,
    /// each reason in a line and how rare it is. Any other wine gets a title on its appellation, no seal, and open,
    /// what its seal requires (CELLAR-R30).
    init(_ certificate: WineCertificate, prevalence: QualityPrevalence? = .current) {
        let isTop = certificate.topPercent != nil
        showsSeal = isTop || certificate.tier == .top
        let count = certificate.awards.count
        let awards = count == 0 ? nil : count == 1
            ? String(localized: "1 award", bundle: .module)
            : String(localized: "\(count) awards", bundle: .module)
        if let top = certificate.topPercent {
            headline = String(localized: "Among the top \(top)% of the world's wines", bundle: .module)
            subline = Self.joined(certificate.basis) ?? Self.joined([certificate.printed, certificate.designation])
        } else if let tier = certificate.tier {
            headline = Self.headline(tier, place: certificate.appellation)
            subline = Self.joined([certificate.printed ?? certificate.category, certificate.designation, awards])
        } else if let designation = certificate.designation {
            headline = designation
            subline = awards
        } else {
            headline = certificate.awards.first?.text ?? ""
            subline = count > 1 ? awards : nil
        }

        var sections: [Section] = []
        if let name = certificate.printed ?? certificate.category {
            var lines = Self.explanation(of: certificate.category, isTop: isTop)
                ?? [certificate.insight].compactMap { $0 }
            if isTop, certificate.tier == .top, let share = prevalence?.share(.top), share > 0 {
                lines.append(String(localized: "Only 1 in \(Int((1 / share).rounded())) wines.", bundle: .module))
            }
            sections.append(Section(title: String(localized: "Appellation", bundle: .module),
                                    value: Self.lead(name, category: certificate.category), lines: lines))
        }
        if let designation = certificate.designation {
            var lines = [certificate.designationNote].compactMap { $0 }
            if isTop, let strength = certificate.designationStrength, strength >= .aged,
               let share = prevalence?.share(strength) {
                let percent = max(1, Int((share * 100).rounded()))
                lines.append(String(localized: "Only \(percent)% of wines.", bundle: .module))
            }
            sections.append(Section(title: String(localized: "Legal term", bundle: .module), value: designation,
                                    lines: lines))
        }
        if !certificate.awards.isEmpty {
            sections.append(Section(title: String(localized: "Awards", bundle: .module),
                                    lines: certificate.awards.map(\.text)))
        }
        self.sections = sections
    }

    /// The title of a wine outside the top: "Authentic Bordeaux Supérieur", "Lisboa, unbound".
    static func headline(_ tier: AppellationTier, place: String?) -> String {
        switch (tier, place) {
        case (.top, _): String(localized: "Among its country's finest", bundle: .module)
        case let (.protected, place?): String(localized: "Authentic \(place)", bundle: .module)
        case (.protected, nil): String(localized: "A wine with a seal of origin", bundle: .module)
        case let (.regional, place?): String(localized: "\(place), unbound", bundle: .module)
        case (.regional, nil): String(localized: "A regional wine, unbound", bundle: .module)
        }
    }

    /// The appellation, leading into what its seal requires: "Bordeaux Supérieur AOC, by law requires:".
    static func lead(_ name: String, category: String?) -> String {
        switch category {
        case "DOC", "DOP", "DO", "AOC", "AOP", "DAC", "Prädikatswein", "Qualitätswein":
            String(localized: "\(name), by law requires:", bundle: .module)
        case "IGT", "IGP", "IG", "Vinho Regional", "Vin de Pays", "Vino de la Tierra", "Landwein":
            String(localized: "\(name), fewer rules than a DOC:", bundle: .module)
        default:
            name
        }
    }

    /// What the seal means, short; lines may bold their lead word. Nil for a category without its own lines, which
    /// falls back on the catalog's.
    static func explanation(of category: String?, isTop: Bool) -> [String]? {
        switch category {
        case "DOCG": [String(localized: "Italy's top level, with an official tasting.", bundle: .module)]
        case "DOCa", "DOQ": [String(localized: "Spain's top level: only Rioja and Priorat.", bundle: .module)]
        case "Grand Cru": [String(localized: "The region's finest vineyards.", bundle: .module)]
        case "Premier Cru": [String(localized: "Just below Grand Cru.", bundle: .module)]
        case "Cru Classé", "Grand Cru Classé", "Premier Grand Cru Classé":
            [String(localized: "Officially ranked among the region's best.", bundle: .module)]
        case "Grosse Lage": [String(localized: "Germany's top vineyards.", bundle: .module)]
        case "DOC", "DOP", "DO", "AOC", "AOP", "DAC", "Prädikatswein", "Qualitätswein":
            [String(localized: "**Region:** 100% local grapes.", bundle: .module),
             String(localized: "**Grapes:** only the permitted ones.", bundle: .module),
             String(localized: "**Method:** a yield limit and an official tasting.", bundle: .module)]
                + (isTop ? [] : [String(localized: "It guarantees the origin, not the quality.", bundle: .module)])
        case "AVA": [String(localized: "A US region: 85% local grapes, no other rules.", bundle: .module)]
        case "VQA": [String(localized: "Canada's seal: local grapes, an official tasting.", bundle: .module)]
        case "WO": [String(localized: "South Africa's seal: local grapes.", bundle: .module)]
        case "IGT", "IGP", "IG", "Vinho Regional", "Vin de Pays", "Vino de la Tierra", "Landwein":
            [String(localized: "**Region:** 85% local grapes.", bundle: .module),
             String(localized: "**Grapes:** international ones allowed.", bundle: .module),
             String(localized: "**Method:** higher yields, freer blends.", bundle: .module)]
        default:
            nil
        }
    }

    private static func joined(_ parts: [String?]) -> String? {
        let parts = parts.compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
