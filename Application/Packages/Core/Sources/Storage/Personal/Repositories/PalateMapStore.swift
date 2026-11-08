import Core
import Foundation
import SwiftData

/// `PalateMapRepository` on the Personal store.
@ModelActor
public actor PalateMapStore: PalateMapRepository, PalateHistoryRewriting {
    public func rewriteHistory(_ history: [MapChange]) throws {
        var descriptor = FetchDescriptor<PalateMapEntity>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        descriptor.fetchLimit = 1
        guard let entity = try modelContext.fetch(descriptor).first else { throw PalateMapStoreError.noMap }
        entity.replace(history: history)
        try modelContext.save()
    }

    public func currentMap() throws -> PalateMap? {
        var descriptor = FetchDescriptor<PalateMapEntity>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.map
    }

    public func history() throws -> [MapChange] {
        var descriptor = FetchDescriptor<PalateMapEntity>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.history ?? []
    }

    /// A rating changes the current map in place: its history keeps the Quiz and every rating since.
    public func saveRatedMap(_ map: PalateMap, wineKey: String, verdict: Verdict, at date: Date) throws {
        var descriptor = FetchDescriptor<PalateMapEntity>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        descriptor.fetchLimit = 1
        guard let entity = try modelContext.fetch(descriptor).first else { throw PalateMapStoreError.noMap }
        entity.apply(map, change: MapChange(date: date, cause: .rating(wineKey: wineKey, verdict: verdict), values: map.values))
        try modelContext.save()
    }

    /// The new map replaces the old one completely; its history starts again with the Quiz (QUIZ-R18a).
    /// Ratings live in their own table and are not touched.
    public func saveQuizMap(_ map: PalateMap, at date: Date) throws {
        for old in try modelContext.fetch(FetchDescriptor<PalateMapEntity>()) {
            modelContext.delete(old)
        }
        let history = [MapChange(date: date, cause: .quiz, values: map.values)]
        modelContext.insert(PalateMapEntity(map: map, createdAt: date, history: history))
        try modelContext.save()
    }
}

/// A rating needs a map to move: there is none before the first Quiz.
public enum PalateMapStoreError: Error {
    case noMap
}
