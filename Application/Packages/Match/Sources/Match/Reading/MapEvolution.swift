import Core
import Foundation

/// How the map changed (YOU-R10): the first map, one per past month with ratings, and today.
public enum MapEvolution {
    /// `history` is oldest first and starts with the Quiz (ARCHITECTURE §2.1).
    public static func snapshots(history: [MapChange], now: Date, calendar: Calendar) -> [MapSnapshot] {
        guard let first = history.first else { return [] }
        var snapshots = [MapSnapshot(kind: .first, date: first.date, map: PalateMap(first.values), winesRated: 0)]
        var rated = 0
        var lastOfMonth: (change: MapChange, rated: Int)?
        let thisMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now

        for change in history.dropFirst() {
            if case .rating = change.cause { rated += 1 }
            if let pending = lastOfMonth, !calendar.isDate(pending.change.date, equalTo: change.date, toGranularity: .month) {
                snapshots.append(endOfMonth(pending, calendar: calendar))
            }
            lastOfMonth = (change, rated)
        }
        if let pending = lastOfMonth, pending.change.date < thisMonth {
            snapshots.append(endOfMonth(pending, calendar: calendar))
        }
        if rated > 0, let last = history.last {
            snapshots.append(MapSnapshot(kind: .today, date: now, map: PalateMap(last.values), winesRated: rated))
        }
        return snapshots
    }

    private static func endOfMonth(_ entry: (change: MapChange, rated: Int), calendar: Calendar) -> MapSnapshot {
        let end = calendar.dateInterval(of: .month, for: entry.change.date).map { $0.end.addingTimeInterval(-1) } ?? entry.change.date
        return MapSnapshot(kind: .endOfMonth, date: end, map: PalateMap(entry.change.values), winesRated: entry.rated)
    }

    /// The change of each axis from a snapshot to the map of today.
    public static func deltas(from old: PalateMap, to current: PalateMap) -> [PalateAxis: Double] {
        Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, current[$0] - old[$0]) })
    }
}
