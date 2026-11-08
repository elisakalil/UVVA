import Core
import Foundation
import Match

struct MapPresentationBuilder {
    func build(from content: YouContentModel) -> MapUIModel? {
        let map = content.map
        let history = content.history
        guard let map else { return nil }
        let reading = MapReading(map: map)
        let start = history.lastIndex { if case .quiz = $0.cause { true } else { false } } ?? 0
        let changes = history.dropFirst(start).reversed()
        let recent = Array(zip(changes.dropFirst(), changes).lazy.compactMap { before, after -> SnapshotUIModel? in
            guard case .rating = after.cause else { return nil }
            let map = PalateMap(after.values)
            let previous = PalateMap(before.values)
            guard map != previous else { return nil }
            let values = MapEvolution.deltas(from: previous, to: map)
            let deltas = PalateAxis.allCases.compactMap { axis -> MapDeltaRow? in
                guard let value = values[axis], value != 0 else { return nil }
                return MapDeltaRow(axis: axis, value: value)
            }
            return SnapshotUIModel(date: after.date, map: map, deltas: deltas)
        }.prefix(6).reversed())
        return MapUIModel(
            map: map,
            highlighted: reading.highlighted,
            dominantPhrase: reading.dominantPhrase,
            readings: PalateAxis.allCases.map { axis in
                let level = MapReading.level(map[axis])
                return MapReadingRow(name: axis.label, level: level, word: MapReading.levelWord(level),
                                     isStrong: reading.leaders(3).contains(axis))
            },
            snapshots: recent,
            lastChange: recent.last.flatMap { lastChange(from: $0.deltas) },
            narrative: reading.narrative
        )
    }

    /// HOME-R16, shown on Over time after a rating.
    private func lastChange(from deltas: [MapDeltaRow]) -> String? {
        guard let change = deltas.max(by: { abs($0.value) < abs($1.value) }),
              abs(change.value) >= AxisChange.threshold else { return nil }
        let axis = change.axis.label.lowercased()
        return change.value > 0
            ? String(localized: "Your last wine raised your \(axis).", bundle: .module)
            : String(localized: "Your last wine lowered your \(axis).", bundle: .module)
    }
}
