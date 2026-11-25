import Core
import Foundation
import Match

/// The public catalog's snapshot as the phone first sees it, without its files.
public struct CatalogSnapshotInfo: Equatable, Sendable {
    public var version: String
    /// Every `CatalogWine` changed after this is in the delta, not in the snapshot.
    public var builtAt: Date
    public var wineCount: Int
    public var prevalence: QualityPrevalence?

    public init(version: String, builtAt: Date, wineCount: Int, prevalence: QualityPrevalence?) {
        self.version = version
        self.builtAt = builtAt
        self.wineCount = wineCount
        self.prevalence = prevalence
    }
}

/// One `CatalogWine` changed since the last sync: a wine to add or replace, or one that left the catalog.
public struct CatalogChange: Equatable, Sendable {
    public var wineKey: String
    /// Nil for a wine that left the catalog.
    public var wine: CatalogWineData?
    public var modifiedAt: Date

    public init(wineKey: String, wine: CatalogWineData?, modifiedAt: Date) {
        self.wineKey = wineKey
        self.wine = wine
        self.modifiedAt = modifiedAt
    }
}

/// The public catalog in CloudKit (ARCHITECTURE §3.2, §4.1, §4.3).
public protocol CatalogCloudService: Sendable {
    /// Nil while the robot has not published one yet.
    func snapshotInfo() async throws -> CatalogSnapshotInfo?
    /// Every wine of the snapshot.
    func snapshotWines() async throws -> [CatalogWineData]
    /// Exact source strings mapped to their pt-BR variants.
    func portugueseTexts() async throws -> [String: String]
    /// Every `CatalogWine` changed after this date.
    func changes(since date: Date) async throws -> [CatalogChange]
    /// The catalog's wines with any of these words in their name or producer.
    func wines(sharing tokens: Set<String>) async throws -> [CatalogWineData]
    /// Sends these readings as the user's contributions; returns the wineKeys CloudKit kept.
    func contribute(_ wines: [CatalogWineData], userID: String) async throws -> Set<String>
}

extension CatalogCloudService {
    public func portugueseTexts() async throws -> [String: String] { [:] }
}
