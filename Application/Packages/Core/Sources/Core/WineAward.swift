import Foundation

/// A medal or a critic's score shown on the bottle (CELLAR-R30): "Gold · Decanter World Wine Awards · 2023",
/// "92 pts · James Suckling · 2021".
public struct WineAward: Equatable, Hashable, Sendable {
    public enum Medal: String, CaseIterable, Sendable {
        case trophy, platinum, doubleGold, gold, silver, bronze, commended

        /// "Double Gold", as the card writes it.
        public var title: String {
            switch self {
            case .trophy: "Trophy"
            case .platinum: "Platinum"
            case .doubleGold: "Double Gold"
            case .gold: "Gold"
            case .silver: "Silver"
            case .bronze: "Bronze"
            case .commended: "Commended"
            }
        }

        /// "gold", "Double Gold", "GOLD MEDAL" → the medal.
        public init?(title: String) {
            let folded = WineText.tokens(title).filter { $0 != "medal" }.joined()
            guard let medal = Self.allCases.first(where: { WineText.tokens($0.title).joined() == folded }) else {
                return nil
            }
            self = medal
        }
    }

    /// The competition or the critic, as `CertificationKeywords` spells it when it knows it.
    public var competition: String
    public var medal: Medal?
    /// A critic's score on 100.
    public var points: Int?
    public var year: Int?

    public init(competition: String, medal: Medal? = nil, points: Int? = nil, year: Int? = nil) {
        self.competition = competition
        self.medal = medal
        self.points = points
        self.year = year
    }

    /// "Gold · Decanter World Wine Awards · 2023", how it is stored and shown.
    public var text: String {
        let grade = medal?.title ?? points.map { "\($0) pts" }
        return [grade, competition, year.map(String.init)].compactMap { $0 }.joined(separator: " · ")
    }

    /// The award back from its `text`; nil for text that is not one, or not a plausible competition: what an older
    /// reading stored from camera noise is dropped (CELLAR-R30).
    public init?(text: String) {
        var parts = text.components(separatedBy: " · ").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count >= 2 else { return nil }
        let year = parts.count >= 3 ? Int(parts[parts.count - 1]) : nil
        if year != nil { parts.removeLast() }
        let grade = parts.removeFirst()
        let competition = parts.joined(separator: " · ")
        guard !competition.isEmpty else { return nil }
        if let medal = Medal(title: grade) {
            self.init(competition: competition, medal: medal, year: year)
        } else if let points = Int(grade.replacingOccurrences(of: " pts", with: "")) {
            self.init(competition: competition, points: points, year: year)
        } else {
            return nil
        }
        guard isPlausible else { return nil }
    }
}

public extension Array where Element == WineAward {
    /// These awards, then those of `others` not already here: the same competition, grade and year, whatever the
    /// spelling.
    func adding(_ others: [WineAward]) -> [WineAward] {
        var seen = Set<String>()
        return (self + others).filter { award in
            let key = WineText.tokens(award.competition).joined(separator: " ")
                + "|\(award.medal?.rawValue ?? "")|\(award.points.map(String.init) ?? "")|\(award.year.map(String.init) ?? "")"
            return seen.insert(key).inserted
        }
    }
}
