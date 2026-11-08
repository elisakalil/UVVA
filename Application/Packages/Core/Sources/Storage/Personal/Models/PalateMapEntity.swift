import Core
import Foundation
import SwiftData

/// The user's palate map, one per account, in the Personal store (ARCHITECTURE §2.1).
/// Synced with CloudKit, so every attribute has a default and nothing is unique.
@Model
public final class PalateMapEntity {
    /// `[PalateAxis: Double]` as JSON.
    var valuesData = Data()
    /// When this map was born ("Keep this map").
    public var createdAt = Date.distantPast
    /// `[MapChange]` as JSON, oldest first. The first entry is the Quiz.
    var historyData = Data()

    init(map: PalateMap, createdAt: Date, history: [MapChange]) {
        self.valuesData = (try? JSONEncoder().encode(map.values)) ?? Data()
        self.createdAt = createdAt
        self.historyData = (try? JSONEncoder().encode(history)) ?? Data()
    }

    public var map: PalateMap {
        PalateMap((try? JSONDecoder().decode([PalateAxis: Double].self, from: valuesData)) ?? [:])
    }

    /// The map after a change, with the change added to the end of the history.
    func apply(_ map: PalateMap, change: MapChange) {
        valuesData = (try? JSONEncoder().encode(map.values)) ?? Data()
        historyData = (try? JSONEncoder().encode(history + [change])) ?? Data()
    }

    /// The history replaced as a whole, and the map set to its last entry (CELLAR-R29).
    func replace(history: [MapChange]) {
        guard let last = history.last else { return }
        valuesData = (try? JSONEncoder().encode(last.values)) ?? Data()
        historyData = (try? JSONEncoder().encode(history)) ?? Data()
    }

    public var history: [MapChange] {
        (try? JSONDecoder().decode([MapChange].self, from: historyData)) ?? []
    }
}
