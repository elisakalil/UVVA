import CloudKit
import Core
import CryptoKit
import Foundation
import Match

/// `CatalogCloudService` on the public CloudKit database. Reading needs no iCloud account; contributing does.
/// The robot (`Application/Robot`) writes `CatalogWine` and `CatalogSnapshot`; the app only reads them.
public final class CloudKitCatalogService: CatalogCloudService {
    private let database: CKDatabase

    public init(containerIdentifier: String = PersonalStore.cloudKitContainer) {
        database = CKContainer(identifier: containerIdentifier).publicCloudDatabase
    }

    private typealias Wine = CatalogSchema.Wine
    private typealias Snapshot = CatalogSchema.Snapshot
    private typealias Contribution = CatalogSchema.Contribution

    /// How many `CatalogWine` each words query brings: enough for a label, few enough to stay fast.
    static let lookupLimit = 40
    /// The words asked, the longest first: they say most about a wine.
    static let lookupTokens = 4

    public func snapshotInfo() async throws -> CatalogSnapshotInfo? {
        guard let record = try await snapshot(keys: [Snapshot.version, Snapshot.builtAt, Snapshot.wineCount,
                                                     Snapshot.prevalence]),
              let version = record[Snapshot.version] as? String,
              let builtAt = record[Snapshot.builtAt] as? Date else { return nil }
        let prevalence = (record[Snapshot.prevalence] as? String).flatMap {
            try? JSONDecoder().decode(QualityPrevalence.self, from: Data($0.utf8))
        }
        return CatalogSnapshotInfo(version: version, builtAt: builtAt,
                                   wineCount: (record[Snapshot.wineCount] as? Int) ?? 0, prevalence: prevalence)
    }

    public func snapshotWines() async throws -> [CatalogWineData] {
        guard let record = try await snapshot(keys: [Snapshot.wines]),
              let url = (record[Snapshot.wines] as? CKAsset)?.fileURL else { throw CatalogCloudError.noSnapshot }
        return try Self.decodeWines(Data(contentsOf: url))
    }

    /// The snapshot's file: `CatalogWinesFile` as zlib-compressed JSON.
    static func decodeWines(_ compressed: Data) throws -> [CatalogWineData] {
        let json = try (compressed as NSData).decompressed(using: .zlib) as Data
        return try JSONDecoder().decode(CatalogWinesFile.self, from: json).wines
    }

    public func portugueseTexts() async throws -> [String: String] {
        guard let record = try await snapshot(keys: [Snapshot.portugueseTexts]),
              let url = (record[Snapshot.portugueseTexts] as? CKAsset)?.fileURL else { return [:] }
        let json = try (Data(contentsOf: url) as NSData).decompressed(using: .zlib) as Data
        return try JSONDecoder().decode([String: String].self, from: json)
    }

    public func changes(since date: Date) async throws -> [CatalogChange] {
        let predicate = NSPredicate(format: "modificationDate > %@", date as NSDate)
        return try await query(Wine.type, predicate, keys: [Wine.data, Wine.status]).compactMap(Self.change)
    }

    public func wines(sharing tokens: Set<String>) async throws -> [CatalogWineData] {
        let asked = tokens.sorted { $0.count != $1.count ? $0.count > $1.count : $0 < $1 }.prefix(Self.lookupTokens)
        var found: [String: CatalogWineData] = [:]
        for token in asked {
            let predicate = NSPredicate(format: "%K CONTAINS %@ AND %K == %@", Wine.tokens, token, Wine.status,
                                        Wine.active)
            let records = try await query(Wine.type, predicate, keys: [Wine.data, Wine.status],
                                          limit: Self.lookupLimit)
            for change in records.compactMap(Self.change) {
                if let wine = change.wine { found[wine.id] = wine }
            }
        }
        return found.values.sorted { $0.id < $1.id }
    }

    public func contribute(_ wines: [CatalogWineData], userID: String) async throws -> Set<String> {
        let encoder = JSONEncoder()
        var saved = Set<String>()
        for batch in wines.chunked(into: 200) {
            let records = try batch.map { wine in
                let record = CKRecord(recordType: Contribution.type,
                                      recordID: CKRecord.ID(recordName: Self.contributionName(wine.id, userID: userID)))
                record[Contribution.wineKey] = wine.id
                record[Contribution.contributor] = userID
                record[Contribution.data] = String(decoding: try encoder.encode(wine), as: UTF8.self)
                return record
            }
            let keys = Dictionary(uniqueKeysWithValues: records.map { ($0.recordID, $0[Contribution.wineKey] as? String) })
            let (results, _) = try await database.modifyRecords(saving: records, deleting: [], savePolicy: .allKeys,
                                                               atomically: false)
            for (id, result) in results {
                if case .success = result, let key = keys[id] ?? nil { saved.insert(key) }
            }
        }
        return saved
    }

    /// One per user and wine: SHA-256 of both, in hex.
    static func contributionName(_ wineKey: String, userID: String) -> String {
        SHA256.hash(data: Data("\(wineKey)\n\(userID)".utf8)).map { String(format: "%02x", $0) }.joined()
    }

    static func change(_ record: CKRecord) -> CatalogChange? {
        let key = record.recordID.recordName
        let modified = record.modificationDate ?? .distantPast
        if record[Wine.status] as? String == Wine.removed {
            return CatalogChange(wineKey: key, wine: nil, modifiedAt: modified)
        }
        guard let json = record[Wine.data] as? String,
              let wine = try? JSONDecoder().decode(CatalogWineData.self, from: Data(json.utf8)) else { return nil }
        return CatalogChange(wineKey: key, wine: wine, modifiedAt: modified)
    }

    private func snapshot(keys: [CKRecord.FieldKey]) async throws -> CKRecord? {
        let id = CKRecord.ID(recordName: Snapshot.recordName)
        do {
            let results = try await database.records(for: [id], desiredKeys: keys)
            switch results[id] {
            case let .success(record): return record
            case let .failure(error): throw error
            case nil: return nil
            }
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    /// Every page of a query. A record type CloudKit does not have yet (`unknownItem`) has no records.
    private func query(_ type: CKRecord.RecordType, _ predicate: NSPredicate, keys: [CKRecord.FieldKey],
                       limit: Int? = nil) async throws -> [CKRecord] {
        var records: [CKRecord] = []
        var page: (matchResults: [(CKRecord.ID, Result<CKRecord, any Error>)], queryCursor: CKQueryOperation.Cursor?)
        do {
            page = try await database.records(matching: CKQuery(recordType: type, predicate: predicate),
                                              desiredKeys: keys,
                                              resultsLimit: limit ?? CKQueryOperation.maximumResults)
        } catch let error as CKError where error.code == .unknownItem {
            return []
        }
        while true {
            for (_, result) in page.matchResults {
                if case let .success(record) = result { records.append(record) }
            }
            guard limit == nil, let cursor = page.queryCursor else { break }
            page = try await database.records(continuingMatchFrom: cursor, desiredKeys: keys)
        }
        return records
    }
}

public enum CatalogCloudError: LocalizedError {
    case noSnapshot

    public var errorDescription: String? {
        "The wine catalog could not be downloaded. Check your connection and try again."
    }
}
