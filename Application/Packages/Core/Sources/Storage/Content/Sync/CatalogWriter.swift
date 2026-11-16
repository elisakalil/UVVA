import Core
import Foundation
import Match
import SwiftData

/// Where the phone's copy of the public catalog stands (`CatalogStateEntity`).
public struct CatalogSyncState: Equatable, Sendable {
    public var lastChange: Date?
    public var lastCheck: Date?
    public var snapshotVersion: String?
    public var prevalence: QualityPrevalence?
    public var queuedEarlierScans = false

    public init(lastChange: Date? = nil, lastCheck: Date? = nil, snapshotVersion: String? = nil,
                prevalence: QualityPrevalence? = nil, queuedEarlierScans: Bool = false) {
        self.lastChange = lastChange
        self.lastCheck = lastCheck
        self.snapshotVersion = snapshotVersion
        self.prevalence = prevalence
        self.queuedEarlierScans = queuedEarlierScans
    }
}

/// A reading waiting to be sent to the public catalog.
public struct PendingContribution: Equatable, Sendable {
    public var wine: CatalogWineData
    public var updatedAt: Date
}

/// Writes the public catalog into the Content store, and keeps the readings waiting to be sent to it
/// (ARCHITECTURE §4.1, §4.3). A wine in `protecting` (in the Cellar or rated) never leaves the phone.
public actor CatalogWriter: StoreActor {
    public nonisolated let executor: StoreExecutor

    public init(modelContainer: ModelContainer) {
        executor = StoreExecutor(modelContainer, label: "app.uvva.store.catalog-sync", qos: .utility)
    }

    static let batchSize = 500

    // MARK: State

    public func state() throws -> CatalogSyncState {
        guard let entity = try stateEntity(creating: false) else { return CatalogSyncState() }
        return CatalogSyncState(
            lastChange: entity.lastChange, lastCheck: entity.lastCheck, snapshotVersion: entity.snapshotVersion,
            prevalence: entity.prevalence.flatMap { try? JSONDecoder().decode(QualityPrevalence.self, from: $0) },
            queuedEarlierScans: entity.queuedEarlierScans)
    }

    public func save(_ state: CatalogSyncState) throws {
        guard let entity = try stateEntity(creating: true) else { return }
        entity.lastChange = state.lastChange
        entity.lastCheck = state.lastCheck
        entity.snapshotVersion = state.snapshotVersion
        entity.prevalence = try state.prevalence.map { try JSONEncoder().encode($0) }
        entity.queuedEarlierScans = state.queuedEarlierScans
        try modelContext.save()
    }

    private func stateEntity(creating: Bool) throws -> CatalogStateEntity? {
        if let found = try modelContext.fetch(FetchDescriptor<CatalogStateEntity>()).first { return found }
        guard creating else { return nil }
        let entity = CatalogStateEntity()
        modelContext.insert(entity)
        return entity
    }

    // MARK: Wines

    /// Every wine on the phone, scanned ones included.
    public func wineCount() throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<WineEntity>())
    }

    /// The snapshot replaces the catalog: its wines are added or replaced, and those of the catalog (or of the old
    /// bundle) it no longer has leave, unless protected. Scanned wines stay until the catalog has them.
    public func replaceAll(with wines: [CatalogWineData], protecting protected: Set<String>) throws {
        var existing: [String: WineEntity] = [:]
        for entity in try modelContext.fetch(FetchDescriptor<WineEntity>()) { existing[entity.wineKey] = entity }
        let incoming = Set(wines.map(\.id))
        for entity in existing.values where entity.source != WineEntity.scannedSource
            && !incoming.contains(entity.wineKey) && !protected.contains(entity.wineKey) {
            modelContext.delete(entity)
        }
        for (index, wine) in wines.enumerated() {
            try Task.checkCancellation()
            WineEntity.upsert(wine, existing: existing[wine.id], in: modelContext)
            if (index + 1) % Self.batchSize == 0 { try modelContext.save() }
        }
        try modelContext.save()
    }

    /// The changes since the last sync: wines added or replaced, and those that left the catalog taken off the
    /// phone, unless protected.
    public func apply(_ changes: [CatalogChange], protecting protected: Set<String>) throws {
        guard !changes.isEmpty else { return }
        let keys = Array(Set(changes.map(\.wineKey)))
        var existing: [String: WineEntity] = [:]
        for batch in keys.chunked(into: 1000) {
            let descriptor = FetchDescriptor<WineEntity>(predicate: #Predicate { batch.contains($0.wineKey) })
            for entity in try modelContext.fetch(descriptor) { existing[entity.wineKey] = entity }
        }
        // The latest change of each wine wins.
        let latest = Dictionary(changes.map { ($0.wineKey, $0) }) { lhs, rhs in lhs.modifiedAt >= rhs.modifiedAt ? lhs : rhs }
        for (index, change) in latest.values.enumerated() {
            try Task.checkCancellation()
            if let wine = change.wine {
                existing[wine.id] = WineEntity.upsert(wine, existing: existing[wine.id], in: modelContext)
            } else if let entity = existing[change.wineKey], !protected.contains(change.wineKey) {
                modelContext.delete(entity)
            }
            if (index + 1) % Self.batchSize == 0 { try modelContext.save() }
        }
        try modelContext.save()
    }

    /// Over `cap`, the catalog wines furthest from the palate leave the phone; scanned and protected wines stay.
    /// Nothing leaves before there is a palate to measure against. Returns how many left.
    @discardableResult
    public func trim(to cap: Int, closestTo map: PalateMap?, protecting protected: Set<String>) throws -> Int {
        let count = try modelContext.fetchCount(FetchDescriptor<WineEntity>())
        guard count > cap, let map else { return 0 }
        var descriptor = FetchDescriptor<WineEntity>()
        descriptor.propertiesToFetch = [\.wineKey, \.source, \.floral, \.body, \.tannin, \.spice, \.oak, \.sweetness,
                                        \.acidity, \.fruit]
        let removable = try modelContext.fetch(descriptor)
            .filter { $0.source != WineEntity.scannedSource && !protected.contains($0.wineKey) }
            .map { (entity: $0, score: -Similarity.distance($0.palateMap, map)) }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score < rhs.score }
                return lhs.entity.wineKey > rhs.entity.wineKey
            }
            .prefix(count - cap)
        for (index, item) in removable.enumerated() {
            modelContext.delete(item.entity)
            if (index + 1) % Self.batchSize == 0 { try modelContext.save() }
        }
        try modelContext.save()
        return removable.count
    }

    // MARK: Contributions

    /// The oldest readings waiting to be sent.
    public func pendingContributions(limit: Int) throws -> [PendingContribution] {
        var descriptor = FetchDescriptor<PendingContributionEntity>(sortBy: [SortDescriptor(\.updatedAt)])
        descriptor.fetchLimit = limit
        let decoder = JSONDecoder()
        return try modelContext.fetch(descriptor).compactMap { entity in
            guard let wine = try? decoder.decode(CatalogWineData.self, from: entity.data) else {
                // A reading that no longer decodes can never be sent.
                modelContext.delete(entity)
                return nil
            }
            return PendingContribution(wine: wine, updatedAt: entity.updatedAt)
        }
    }

    /// Takes off the queue the readings CloudKit has, unless the wine was read again while they were sent.
    public func removeSent(_ sent: [PendingContribution]) throws {
        guard !sent.isEmpty else { return }
        let dates = Dictionary(sent.map { ($0.wine.id, $0.updatedAt) }) { first, _ in first }
        let keys = Array(dates.keys)
        let descriptor = FetchDescriptor<PendingContributionEntity>(predicate: #Predicate { keys.contains($0.wineKey) })
        for entity in try modelContext.fetch(descriptor) where entity.updatedAt <= (dates[entity.wineKey] ?? .distantPast) {
            modelContext.delete(entity)
        }
        try modelContext.save()
    }

    /// The wines scanned before the public catalog existed, queued once so they reach it too.
    public func queueEarlierScans() throws {
        var state = try state()
        guard !state.queuedEarlierScans else { return }
        let scanned = WineEntity.scannedSource
        for entity in try modelContext.fetch(FetchDescriptor<WineEntity>(predicate: #Predicate { $0.source == scanned })) {
            try PendingContributionEntity.enqueue(CatalogStore.wine(entity), in: modelContext)
        }
        state.queuedEarlierScans = true
        try save(state)
    }

    /// An account deleted: what it read and did not send yet is never sent.
    public func clearPending() throws {
        try modelContext.delete(model: PendingContributionEntity.self)
        try modelContext.save()
    }
}
