import Core
import Foundation
import SwiftData

/// `CellarRepository` on the Personal store.
@ModelActor
public actor CellarStore: CellarRepository {
    public func wineKeys() throws -> Set<String> {
        Set(try modelContext.fetch(FetchDescriptor<CellarEntryEntity>()).map(\.wineKey))
    }

    public func addWantToTry(_ wine: Wine) throws {
        try addWantToTry(wine, at: Date())
    }

    func addWantToTry(_ wine: Wine, at date: Date) throws {
        let key = wine.id
        var existing = FetchDescriptor<CellarEntryEntity>(predicate: #Predicate { $0.wineKey == key })
        existing.fetchLimit = 1
        guard try modelContext.fetch(existing).isEmpty else { return }
        let entry = CellarEntryEntity(wineKey: wine.id, status: .wantToTry, date: date)
        entry.name = wine.name
        entry.producer = wine.producer
        entry.vintage = wine.vintage
        entry.type = wine.type
        entry.origin = wine.origin
        entry.grapes = wine.grapes
        entry.alcohol = wine.alcohol
        entry.classification = wine.classification
        modelContext.insert(entry)
        try modelContext.save()
    }
}
