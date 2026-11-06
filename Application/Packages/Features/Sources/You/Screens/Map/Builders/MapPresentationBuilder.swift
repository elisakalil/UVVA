import Core
import Foundation
import Match

struct MapPresentationBuilder {
    func build(from content: YouContentModel, selectedSnapshot: Int?, now: Date, calendar: Calendar) -> MapUIModel? {
        let map = content.map
        let history = content.history
        guard let map else { return nil }
        let reading = MapReading(map: map)
        let snapshots = MapEvolution.snapshots(history: history, now: now, calendar: calendar)
        let selected = min(selectedSnapshot ?? max(snapshots.count - 1, 0), max(snapshots.count - 1, 0))
        let chosen = snapshots.indices.contains(selected) ? snapshots[selected] : nil
        let comparison = chosen.flatMap { $0.kind == .today || snapshots.count == 1 ? nil : $0.map }
        let deltas = comparison.map { MapEvolution.deltas(from: $0, to: map) } ?? [:]
        return MapUIModel(
            readOn: history.last.map { String(localized: "Read \(Self.day($0.date))", bundle: .module) } ?? "",
            map: map,
            highlighted: reading.highlighted,
            dominantPhrase: reading.dominantPhrase,
            readings: PalateAxis.allCases.map { axis in
                let level = MapReading.level(map[axis])
                return MapReadingRow(name: axis.label, level: level, word: MapReading.levelWord(level),
                                     isStrong: reading.leaders(3).contains(axis))
            },
            showsOverTime: history.contains { if case .rating = $0.cause { true } else { false } },
            snapshots: snapshots.enumerated().map { index, snapshot in
                SnapshotUIModel(id: index, label: Self.label(snapshot, calendar: calendar),
                                detail: Self.detail(snapshot), isNew: snapshot.kind == .today)
            },
            selected: selected,
            comparison: comparison,
            deltas: PalateAxis.allCases.map { axis in
                MapDeltaRow(name: axis.label, delta: Self.delta(deltas[axis] ?? 0))
            },
            lastChange: lastChange(in: history),
            narrative: reading.narrative
        )
    }

    /// HOME-R16, shown on Over time after a rating.
    private func lastChange(in history: [MapChange]) -> String? {
        guard history.count >= 2, case .rating = history[history.count - 1].cause else { return nil }
        let before = PalateMap(history[history.count - 2].values)
        let after = PalateMap(history[history.count - 1].values)
        // Ties keep the canonical order (QUIZ-R02).
        let moved = PalateAxis.allCases.max { abs(after[$0] - before[$0]) < abs(after[$1] - before[$1]) }
        guard let axis = moved, abs(after[axis] - before[axis]) >= AxisChange.threshold else { return nil }
        return after[axis] > before[axis]
            ? String(localized: "Your last wine raised your \(axis.label.lowercased()).", bundle: .module)
            : String(localized: "Your last wine lowered your \(axis.label.lowercased()).", bundle: .module)
    }

    static func day(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated))
    }

    static func label(_ snapshot: MapSnapshot, calendar: Calendar) -> String {
        switch snapshot.kind {
        case .first: String(localized: "First", bundle: .module)
        case .endOfMonth: snapshot.date.formatted(.dateTime.month(.abbreviated))
        case .today: String(localized: "Today", bundle: .module)
        }
    }

    static func detail(_ snapshot: MapSnapshot) -> String {
        switch snapshot.kind {
        case .first: String(localized: "First map · 0 wines rated", bundle: .module)
        case .endOfMonth: String(localized: "\(snapshot.winesRated) wines rated", bundle: .module)
        case .today: String(localized: "Today · \(snapshot.winesRated) wines rated", bundle: .module)
        }
    }

    static func delta(_ value: Double) -> String {
        guard abs(value) >= 0.05 else { return "—" }
        return (value > 0 ? "+" : "−") + String(format: "%.1f", abs(value))
    }

}
