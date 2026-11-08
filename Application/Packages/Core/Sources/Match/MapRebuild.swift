import Core
import Foundation

/// CELLAR-R29: the map is rebuilt from the Quiz, reapplying in date order the ratings that still exist.
public enum MapRebuild {
    /// The history with every rating of `wineKey` given `verdict`, or taken out when `verdict` is nil.
    /// A wine missing from `wines` (scanned, never in the catalog) keeps the move it made on the axes.
    /// A history that does not start with the Quiz comes back as it was.
    public static func rebuild(_ history: [MapChange], wines: [String: Wine],
                               changing wineKey: String, to verdict: Verdict?) -> [MapChange] {
        guard let quiz = history.first, quiz.cause == .quiz else { return history }
        var rebuilt = [quiz]
        var map = PalateMap(quiz.values)
        var previous = quiz.values
        for change in history.dropFirst() {
            defer { previous = change.values }
            guard case let .rating(key, oldVerdict) = change.cause else { continue }
            guard let newVerdict = key == wineKey ? verdict : oldVerdict else { continue }
            if let wine = wines[key] {
                map = MapUpdate.apply(newVerdict, wine: wine.profile, to: map).map
            } else {
                map = shifted(map, by: change.values, from: previous)
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
