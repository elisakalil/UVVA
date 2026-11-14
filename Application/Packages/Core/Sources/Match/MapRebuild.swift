import Core
import Foundation

/// CELLAR-R29: the map is rebuilt from the Quiz, reapplying in date order the ratings that still exist.
public enum MapRebuild {
    /// The history with every rating of `wineKey` given `verdict`, or taken out when `verdict` is nil.
    /// A dated replacement counts as a new evaluation and is applied after the remaining ratings.
    /// A wine missing from `wines` (scanned, never in the catalog) keeps the move it made on the axes.
    /// A history that does not start with the Quiz comes back as it was.
    public static func rebuild(_ history: [MapChange], wines: [String: Wine],
                               changing wineKey: String, to verdict: Verdict?, at date: Date? = nil) -> [MapChange] {
        guard let quiz = history.first, quiz.cause == .quiz else { return history }
        var rebuilt = [quiz]
        var map = PalateMap(quiz.values)
        var ratings = Array(zip(history, history.dropFirst()))
        if let date, let verdict,
           let index = ratings.lastIndex(where: { _, change in
               if case let .rating(key, _) = change.cause { return key == wineKey }
               return false
           }) {
            let (previous, original) = ratings.remove(at: index)
            var change = original
            ratings.removeAll { _, change in
                if case let .rating(key, _) = change.cause { return key == wineKey }
                return false
            }
            change.date = date
            change.cause = .rating(wineKey: wineKey, verdict: verdict)
            ratings.append((previous, change))
        }
        for (previous, change) in ratings {
            guard case let .rating(key, oldVerdict) = change.cause else { continue }
            guard let newVerdict = key == wineKey ? verdict : oldVerdict else { continue }
            if let wine = wines[key] {
                map = MapUpdate.apply(newVerdict, wine: wine.profile, to: map).map
            } else {
                map = shifted(map, by: change.values, from: previous.values)
            }
            rebuilt.append(MapChange(date: change.date, cause: .rating(wineKey: key, verdict: newVerdict), values: map.values))
        }
        return rebuilt
    }

    /// The same move the rating once made, from wherever the map is now.
    private static func shifted(_ map: PalateMap, by after: [PalateAxis: Double], from before: [PalateAxis: Double]) -> PalateMap {
        var values: [PalateAxis: Double] = [:]
        for axis in PalateAxis.allCases {
            let delta = (after[axis] ?? 0) - (before[axis] ?? 0)
            values[axis] = min(max(map[axis] + delta, PalateMap.range.lowerBound), PalateMap.range.upperBound)
        }
        return PalateMap(values)
    }
}
