import Core
import Foundation
import SwiftData

/// `CellarRepository` on the Personal store.
@ModelActor
public actor CellarStore: CellarRepository {
    public func wineKeys() throws -> Set<String> {
        Set(try modelContext.fetch(FetchDescriptor<CellarEntryEntity>()).map(\.wineKey))
    }

    public func tastedWineKeys() throws -> Set<String> {
        let tasted = CellarEntryEntity.Status.tasted.rawValue
        let descriptor = FetchDescriptor<CellarEntryEntity>(predicate: #Predicate { $0.status == tasted })
        return Set(try modelContext.fetch(descriptor).map(\.wineKey))
    }

    public func addWantToTry(_ wine: Wine) throws {
        try addWantToTry(wine, at: Date())
    }

    func addWantToTry(_ wine: Wine, at date: Date) throws {
        guard try entry(for: wine.id) == nil else { return }
        let entry = CellarEntryEntity(wineKey: wine.id, status: .wantToTry, date: date)
        entry.copyFacts(of: wine)
        modelContext.insert(entry)
        try modelContext.save()
    }

    public func addTasted(_ wine: Wine, verdict: Verdict) throws {
        try addTasted(wine, verdict: verdict, at: Date())
    }

    func addTasted(_ wine: Wine, verdict: Verdict, at date: Date) throws {
        let entry: CellarEntryEntity
        if let existing = try self.entry(for: wine.id) {
            entry = existing
            entry.status = CellarEntryEntity.Status.tasted.rawValue
            entry.updatedAt = date
        } else {
            entry = CellarEntryEntity(wineKey: wine.id, status: .tasted, date: date)
            entry.copyFacts(of: wine)
            modelContext.insert(entry)
        }
        entry.verdict = verdict.rawValue
        try modelContext.save()
    }

    private func entry(for key: String) throws -> CellarEntryEntity? {
        var descriptor = FetchDescriptor<CellarEntryEntity>(predicate: #Predicate { $0.wineKey == key })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}

private extension CellarEntryEntity {
    /// The entry keeps its own copy of the wine's facts (CELLAR.md §2).
    func copyFacts(of wine: Wine) {
        name = wine.name
        producer = wine.producer
        vintage = wine.vintage
        type = wine.type
        origin = wine.origin
        grapes = wine.grapes
        alcohol = wine.alcohol
        classification = wine.classification
    }
}
