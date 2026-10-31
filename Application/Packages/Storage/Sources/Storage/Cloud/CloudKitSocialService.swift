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
        let record = CKRecord(recordType: RecordType.friendRequest, recordID: CKRecord.ID(recordName: "\(from)-\(to)"))
        record["from"] = from
        record["to"] = to
        record["status"] = "pending"
        _ = try await database.modifyRecords(saving: [record], deleting: [], savePolicy: .allKeys)
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
