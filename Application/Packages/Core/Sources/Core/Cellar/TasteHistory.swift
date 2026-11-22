import Foundation

/// How well the user knows a grape or a region, from the wines they rated in the Cellar.
public enum Familiarity: Equatable, Sendable {
    /// More than two wines rated Yes, and more Yes than No.
    case likes
    /// More than two wines rated No, and more No than Yes.
    case dislikes
    /// Rated at least once, but not enough to say.
    case knowsLittle
    /// Never rated.
    case unknown

    /// Above this many Yes (or No) the user likes (or does not like) it.
    static let enough = 2

    init(yes: Int, no: Int, rated: Int) {
        if yes > Self.enough, yes > no {
            self = .likes
        } else if no > Self.enough, no > yes {
            self = .dislikes
        } else {
            self = rated > 0 ? .knowsLittle : .unknown
        }
    }

    /// The order a blend's grapes are told in: what the user is sure of first.
    var weight: Int {
        switch self {
        case .likes: 3
        case .dislikes: 2
        case .knowsLittle: 1
        case .unknown: 0
        }
    }
}

/// How many wines with a grape, or from a region, the user rated, and how.
public struct Tally: Equatable, Sendable {
    public var yes: Int
    public var no: Int
    public var rated: Int

    init(_ verdicts: [Verdict]) {
        yes = verdicts.filter { $0 == .yes }.count
        no = verdicts.filter { $0 == .no }.count
        rated = verdicts.count
    }

    public var familiarity: Familiarity { Familiarity(yes: yes, no: no, rated: rated) }
}

/// The wines the user rated, read for grapes and regions. Names are compared folded ("Touriga-Nacional" is
/// "Touriga Nacional"). A wine Not yet tasted does not count.
public struct TasteHistory: Equatable, Sendable {
    private struct Rated: Equatable, Sendable {
        var grapes: Set<String>
        var region: String?
        var verdict: Verdict
    }

    private let rated: [Rated]

    public init(entries: [CellarEntry]) {
        rated = entries.compactMap { entry in
            guard let verdict = entry.verdict else { return nil }
            return Rated(grapes: Set(entry.grapes.map(Self.key)), region: entry.region.map(Self.key), verdict: verdict)
        }
    }

    public func grape(_ grape: String) -> Familiarity { tally(grape: grape).familiarity }

    public func region(_ region: String) -> Familiarity { tally(region: region).familiarity }

    /// How the wines with this grape were rated.
    public func tally(grape: String) -> Tally {
        let key = Self.key(grape)
        return Tally(rated.filter { $0.grapes.contains(key) }.map(\.verdict))
    }

    /// How the wines from this region were rated.
    public func tally(region: String) -> Tally {
        let key = Self.key(region)
        return Tally(rated.filter { $0.region == key }.map(\.verdict))
    }

    /// Of a blend's grapes, the one the user knows best: liked first, then not liked, then barely known; in the
    /// wine's order on a tie. Nil for a wine with no grape.
    public func telling(_ grapes: [String]) -> (grape: String, tally: Tally)? {
        grapes
            .filter { !Self.key($0).isEmpty }
            .map { ($0, tally(grape: $0)) }
            .enumerated()
            .max { lhs, rhs in
                lhs.element.1.familiarity.weight == rhs.element.1.familiarity.weight
                    ? lhs.offset > rhs.offset
                    : lhs.element.1.familiarity.weight < rhs.element.1.familiarity.weight
            }?
            .element
    }

    private static func key(_ name: String) -> String {
        WineText.tokens(name).joined(separator: " ")
    }
}
