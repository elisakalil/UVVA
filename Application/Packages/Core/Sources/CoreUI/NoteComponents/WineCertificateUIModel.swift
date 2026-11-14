import Core
import Foundation
import Match

/// The certificate card of a wine (CELLAR-R30), in WineDetail, the new note and a saved note. Closed, two lines: the
/// "Top X%" when the wine is in the top 10 %, or else the appellation's level in plain words, and under it what it
/// rests on. Open,
/// one section per criterion: the appellation, the legal term, the awards, and how the "Top X%" is worked out.
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
    public var moreText = String(localized: "More", bundle: .module)
    public var lessText = String(localized: "Less", bundle: .module)

    public init(headline: String, subline: String? = nil, sections: [Section] = []) {
        self.headline = headline
        self.subline = subline
        self.sections = sections
    }

    /// Nil for a wine with nothing that certifies it: the card is not shown.
    public init?(wine: Wine, prevalence: QualityPrevalence? = .current) {
        guard let certificate = Certification.make(for: wine, prevalence: prevalence) else { return nil }
        self.init(certificate)
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

    init(_ certificate: WineCertificate) {
        let level = certificate.tier.map(Self.level)
        // A regional wine says its place; the others say their category too, which is what ranks them.
        let place = certificate.tier == .regional
            ? certificate.appellation ?? certificate.category
            : certificate.printed ?? certificate.category
        let count = certificate.awards.count
        let awards = count == 0 ? nil : count == 1
            ? String(localized: "1 award", bundle: .module)
            : String(localized: "\(count) awards", bundle: .module)
        if let top = certificate.topPercent {
            headline = String(localized: "Top \(top)% of the world's wines", bundle: .module)
            subline = Self.joined([level, place, certificate.designation, awards])
        } else if let level {
            headline = level
            subline = Self.joined([place, certificate.designation, awards])
        } else if let designation = certificate.designation {
            headline = designation
            subline = awards
        } else {
            headline = certificate.awards.first?.text ?? ""
            subline = count > 1 ? awards : nil
        }

        var sections: [Section] = []
        if certificate.printed != nil || certificate.category != nil {
            sections.append(Section(title: String(localized: "Appellation", bundle: .module),
                                    value: Self.joined([certificate.printed ?? certificate.category, level]),
                                    lines: [certificate.insight].compactMap { $0 }))
        }
        if let designation = certificate.designation {
            sections.append(Section(title: String(localized: "Legal term", bundle: .module), value: designation,
                                    lines: [certificate.designationNote].compactMap { $0 }))
        }
        if !certificate.awards.isEmpty {
            sections.append(Section(title: String(localized: "Awards", bundle: .module),
                                    lines: certificate.awards.map(\.text)))
        }
        if let top = certificate.topPercent {
            // "Trophy · Concurso Vinhos de Portugal." ends its own sentence: one full stop, not two.
            let basis = certificate.basis.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ". ")) }
                .joined(separator: ", ")
            sections.append(Section(
                title: String(localized: "How UVVA estimates it", bundle: .module),
                lines: [String(localized: "About \(top)% of the world's wines show signals at least as strong: \(basis). An estimate from the label, measured on UVVA's catalog.", bundle: .module)]))
        }
        self.sections = sections
    }

    /// The appellation's level, as the card names it: what it promises the drinker, not the legal term.
    static func level(_ tier: AppellationTier) -> String {
        switch tier {
        case .top: String(localized: "Among its country's finest", bundle: .module)
        case .protected: String(localized: "Made by strict local rules", bundle: .module)
        case .regional: String(localized: "Regional, free to experiment", bundle: .module)
        }
    }

    private static func joined(_ parts: [String?]) -> String? {
        let parts = parts.compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
