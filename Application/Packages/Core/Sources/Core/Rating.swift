import Foundation

/// One answer to "Would you drink it again?" and how it moved each axis (SHARED-R10).
public struct Rating: Equatable, Sendable {
    public var wineKey: String
    public var verdict: Verdict
    public var date: Date
    public var deltas: [PalateAxis: Double]

    public init(wineKey: String, verdict: Verdict, date: Date, deltas: [PalateAxis: Double]) {
        self.wineKey = wineKey
        self.verdict = verdict
        self.date = date
        self.deltas = deltas
    }

    /// Every wine rated since the Quiz, whether or not it went to the Cellar (SHARED-R11).
    public static func wineKeys(in history: [MapChange]) -> Set<String> {
        Set(history.compactMap { if case let .rating(wineKey, _) = $0.cause { wineKey } else { nil } })
    }

    /// The last rating in a map's history, with how far it moved each axis from the entry before it (SHARED-R10).
    /// Nil when nothing after the Quiz is a rating.
    public static func last(in history: [MapChange]) -> Rating? {
        guard let index = history.lastIndex(where: { if case .rating = $0.cause { true } else { false } }),
              index > 0,
              case let .rating(wineKey, verdict) = history[index].cause
        else { return nil }
        let after = history[index].values
        let before = history[index - 1].values
        var deltas: [PalateAxis: Double] = [:]
        for axis in PalateAxis.allCases {
            deltas[axis] = (after[axis] ?? 0) - (before[axis] ?? 0)
        }
        return Rating(wineKey: wineKey, verdict: verdict, date: history[index].date, deltas: deltas)
    }
}
