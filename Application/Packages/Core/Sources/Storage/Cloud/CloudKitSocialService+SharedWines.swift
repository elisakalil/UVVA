import CloudKit
import Core
import Foundation

/// FRI-R11b, R11c: wines sent to friends, as `SharedWine` records of the public database, named
/// `<from>-<to>-<wine>`, and the push that tells the friend. Only the sender can change or delete a record.
///
/// The record type needs `to` and `from` queryable and `sentAt` sortable in the CloudKit schema (deployed to
/// production with the other public types).
extension CloudKitSocialService: WineSharingService {
    public func sendWine(_ wine: Wine, from userID: String, fromName: String, to friendID: String) async throws {
        let id = CKRecord.ID(recordName: "\(userID)-\(friendID)-\(wine.id)")
        // Sending again moves the wine to the top, and pushes again.
        let record = try await existing(id) ?? CKRecord(recordType: RecordType.sharedWine, recordID: id)
        record["from"] = userID
        record["fromName"] = fromName
        record["to"] = friendID
        record["wineID"] = wine.id
        record["wineName"] = wine.name
        record["sentAt"] = Date()
        record["snapshot"] = (try? JSONEncoder().encode(SharedWineSnapshot(wine))).flatMap { String(data: $0, encoding: .utf8) }
        _ = try await database.modifyRecords(saving: [record], deleting: [], savePolicy: .changedKeys)
    }

    public func sharedWines(to userID: String) async throws -> [SharedWineRecord] {
        try await sharedWineRecords(matching: NSPredicate(format: "to == %@", userID))
            .compactMap(Self.sharedWine)
            .sorted { $0.sentAt > $1.sentAt }
    }

    public func sharedWine(id: String) async throws -> SharedWineRecord? {
        try await existing(CKRecord.ID(recordName: id)).flatMap(Self.sharedWine)
    }

    public func subscribeToSharedWines(userID: String) async throws {
        let subscription = CKQuerySubscription(
            recordType: RecordType.sharedWine, predicate: NSPredicate(format: "to == %@", userID),
            subscriptionID: SharedWinePush.subscriptionPrefix + userID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate])
        let info = CKSubscription.NotificationInfo()
        info.alertLocalizationKey = SharedWinePush.alertKey
        info.alertLocalizationArgs = ["fromName", "wineName"]
        info.soundName = "default"
        subscription.notificationInfo = info
        _ = try await database.modifySubscriptions(saving: [subscription], deleting: [])
    }

    /// The wines this account sent, for the deletion of the account (YOU-R27).
    func sharedWineIDs(from userID: String) async throws -> [CKRecord.ID] {
        try await sharedWineRecords(matching: NSPredicate(format: "from == %@", userID)).map(\.recordID)
    }

    /// Until the first wine is sent the type does not exist and the query fails with `unknownItem`: none.
    private func sharedWineRecords(matching predicate: NSPredicate) async throws -> [CKRecord] {
        var records: [CKRecord] = []
        var page: (matchResults: [(CKRecord.ID, Result<CKRecord, any Error>)], queryCursor: CKQueryOperation.Cursor?)
        do {
            page = try await database.records(matching: CKQuery(recordType: RecordType.sharedWine, predicate: predicate))
        } catch let error as CKError where error.code == .unknownItem {
            return []
        }
        while true {
            records += page.matchResults.compactMap { try? $0.1.get() }
            guard let cursor = page.queryCursor else { break }
            page = try await database.records(continuingMatchFrom: cursor)
        }
        return records
    }

    private func existing(_ id: CKRecord.ID) async throws -> CKRecord? {
        do {
            return try await database.record(for: id)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    static func sharedWine(from record: CKRecord) -> SharedWineRecord? {
        guard let from = record["from"] as? String, let to = record["to"] as? String,
              let wineID = record["wineID"] as? String else { return nil }
        let snapshot = (record["snapshot"] as? String).flatMap {
            try? JSONDecoder().decode(SharedWineSnapshot.self, from: Data($0.utf8))
        }
        return SharedWineRecord(id: record.recordID.recordName, from: from, fromName: record["fromName"] as? String ?? "",
                                to: to, wineID: wineID, wineName: record["wineName"] as? String ?? snapshot?.name ?? "",
                                sentAt: record["sentAt"] as? Date ?? record.creationDate ?? .distantPast,
                                snapshot: snapshot)
    }
}
