import Core
import Foundation
import SwiftData

/// A wine read on a label and not yet sent to the public catalog as the user's `WineContribution` (ARCHITECTURE
/// §4.3). One per wine: a new reading replaces it. It leaves once CloudKit has it.
@Model
public final class PendingContributionEntity {
    #Unique<PendingContributionEntity>([\.wineKey])

    public var wineKey: String
    /// `CatalogWineData` as JSON: the wine's facts only, never a photo, a note or a verdict.
    public var data: Data
    public var updatedAt: Date

    init(wineKey: String, data: Data, updatedAt: Date) {
        self.wineKey = wineKey
        self.data = data
        self.updatedAt = updatedAt
    }

    /// Queues this reading of the wine, replacing an older one of the same wine. Saved with the context.
    static func enqueue(_ wine: Wine, in context: ModelContext, at date: Date = Date()) throws {
        let data = try JSONEncoder().encode(CatalogWineData(wine))
        let key = wine.id
        var descriptor = FetchDescriptor<PendingContributionEntity>(predicate: #Predicate { $0.wineKey == key })
        descriptor.fetchLimit = 1
        if let found = try context.fetch(descriptor).first {
            found.data = data
            found.updatedAt = date
        } else {
            context.insert(PendingContributionEntity(wineKey: key, data: data, updatedAt: date))
        }
    }
}
