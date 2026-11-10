import CloudKit
import Core
import Foundation

/// `SocialService` on the public CloudKit database (ARCHITECTURE §3.2, §4.4).
/// Records are named after their key, so a duplicate cannot be created without a server.
public final class CloudKitSocialService: SocialService {
    private let database: CKDatabase

    public init(containerIdentifier: String = PersonalStore.cloudKitContainer) {
        database = CKContainer(identifier: containerIdentifier).publicCloudDatabase
    }

    enum RecordType {
        static let contactKey = "ContactKey"
        static let publicProfile = "PublicProfile"
        static let friendRequest = "FriendRequest"
    }

    public func publishContactKey(phone: String, userID: String) async throws -> Bool {
        let id = CKRecord.ID(recordName: ContactKey.make(phone: phone))
        if let existing = try await record(id) {
            return existing["userID"] as? String == userID
        }
        let record = CKRecord(recordType: RecordType.contactKey, recordID: id)
        record["userID"] = userID
        _ = try await database.save(record)
        return true
    }

    public func accounts(forPhones phones: [String]) async throws -> [String: PublicProfile] {
        let keyToPhone = Dictionary(phones.map { (ContactKey.make(phone: $0), $0) }) { first, _ in first }
        var phoneToUser: [String: String] = [:]
        for batch in Array(keyToPhone.keys).chunked(into: 200) {
            let results = try await database.records(for: batch.map { CKRecord.ID(recordName: $0) })
            for (id, result) in results {
                if case let .success(record) = result, let user = record["userID"] as? String,
                   let phone = keyToPhone[id.recordName] {
                    phoneToUser[phone] = user
                }
            }
        }
        var profiles: [String: PublicProfile] = [:]
        for batch in Array(Set(phoneToUser.values)).chunked(into: 200) {
            let results = try await database.records(for: batch.map { CKRecord.ID(recordName: $0) })
            for (id, result) in results {
                if case let .success(record) = result { profiles[id.recordName] = Self.profile(from: record) }
            }
        }
        return phoneToUser.compactMapValues { profiles[$0] }
    }

    public func sendFriendRequest(from: String, to: String) async throws {
        let record = CKRecord(recordType: RecordType.friendRequest, recordID: Self.requestID(from: from, to: to))
        record["from"] = from
        record["to"] = to
        record["status"] = "pending"
        _ = try await database.modifyRecords(saving: [record], deleting: [], savePolicy: .allKeys)
    }

    public func friendRequests(to userID: String) async throws -> [FriendRequestRecord] {
        try await requests(matching: NSPredicate(format: "to == %@", userID))
    }

    public func friendRequests(from userID: String) async throws -> [FriendRequestRecord] {
        try await requests(matching: NSPredicate(format: "from == %@", userID))
    }

    public func deleteFriendRequest(from: String, to: String) async throws {
        try await delete([Self.requestID(from: from, to: to)])
    }

    public func profiles(ids: [String]) async throws -> [String: PublicProfile] {
        var profiles: [String: PublicProfile] = [:]
        for batch in Array(Set(ids)).chunked(into: 200) {
            let results = try await database.records(for: batch.map { CKRecord.ID(recordName: $0) })
            for (id, result) in results {
                if case let .success(record) = result { profiles[id.recordName] = Self.profile(from: record) }
            }
        }
        return profiles
    }

    public func publish(_ profile: PublicProfile) async throws {
        let record = CKRecord(recordType: RecordType.publicProfile, recordID: CKRecord.ID(recordName: profile.id))
        record["firstName"] = profile.firstName
        record["hasMap"] = profile.hasMap ? 1 : 0
        let values: String? = profile.map.flatMap { map in
            (try? JSONEncoder().encode(map.values)).map { String(decoding: $0, as: UTF8.self) }
        }
        record["values"] = values as CKRecordValue?
        _ = try await database.modifyRecords(saving: [record], deleting: [], savePolicy: .allKeys)
    }

    public func removeContactKey(phone: String) async throws {
        try await delete([CKRecord.ID(recordName: ContactKey.make(phone: phone))])
    }

    /// Records that are already gone count as deleted.
    public func deleteAccount(userID: String, phone: String?) async throws {
        var ids = [CKRecord.ID(recordName: userID)]
        if let phone { ids.append(CKRecord.ID(recordName: ContactKey.make(phone: phone))) }
        // Requests made to this account belong to their senders and cannot be deleted here; without the
        // public profile they are left out of every list.
        ids += try await friendRequests(from: userID).map { Self.requestID(from: $0.from, to: $0.to) }
        try await delete(ids)
    }

    private func delete(_ ids: [CKRecord.ID]) async throws {
        for batch in ids.chunked(into: 200) {
            let (_, results) = try await database.modifyRecords(saving: [], deleting: batch)
            for result in results.values {
                if case let .failure(error) = result, (error as? CKError)?.code != .unknownItem { throw error }
            }
        }
    }

    /// Every page of a `FriendRequest` query. Needs `from` and `to` queryable in the Dashboard.
    /// CloudKit creates a record type when its first record is saved. Until someone sends a request the type is not
    /// there and the query fails with `unknownItem`, which means there are no requests.
    private func requests(matching predicate: NSPredicate) async throws -> [FriendRequestRecord] {
        var records: [FriendRequestRecord] = []
        var page: (matchResults: [(CKRecord.ID, Result<CKRecord, any Error>)], queryCursor: CKQueryOperation.Cursor?)
        do {
            page = try await database.records(matching: CKQuery(recordType: RecordType.friendRequest, predicate: predicate),
                                              desiredKeys: ["from", "to"])
        } catch let error as CKError where error.code == .unknownItem {
            return []
        }
        while true {
            for (_, result) in page.matchResults {
                if case let .success(record) = result, let request = Self.request(from: record) { records.append(request) }
            }
            guard let cursor = page.queryCursor else { break }
            page = try await database.records(continuingMatchFrom: cursor, desiredKeys: ["from", "to"])
        }
        return records
    }

    static func requestID(from: String, to: String) -> CKRecord.ID {
        CKRecord.ID(recordName: "\(from)-\(to)")
    }

    static func request(from record: CKRecord) -> FriendRequestRecord? {
        guard let from = record["from"] as? String, let to = record["to"] as? String else { return nil }
        return FriendRequestRecord(from: from, to: to, createdAt: record.creationDate ?? .distantPast)
    }

    private func record(_ id: CKRecord.ID) async throws -> CKRecord? {
        do {
            return try await database.record(for: id)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    static func profile(from record: CKRecord) -> PublicProfile {
        let values = (record["values"] as? String).flatMap {
            try? JSONDecoder().decode([PalateAxis: Double].self, from: Data($0.utf8))
        }
        return PublicProfile(id: record.recordID.recordName, firstName: record["firstName"] as? String ?? "",
                             map: values.map(PalateMap.init), hasMap: (record["hasMap"] as? Int ?? 0) == 1)
    }
}
