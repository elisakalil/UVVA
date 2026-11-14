import CryptoKit
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A JSON value, for the CloudKit Web Services bodies.
public enum JSON: Codable, Equatable, Sendable {
    case string(String), number(Double), bool(Bool), array([JSON]), object([String: JSON]), null

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode([JSON].self) { self = .array(value) }
        else { self = .object(try container.decode([String: JSON].self)) }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value): try container.encode(value)
        case let .number(value): try container.encode(value)
        case let .bool(value): try container.encode(value)
        case let .array(value): try container.encode(value)
        case let .object(value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    public subscript(key: String) -> JSON? {
        if case let .object(object) = self { return object[key] }
        return nil
    }

    public var string: String? { if case let .string(value) = self { value } else { nil } }
    public var number: Double? { if case let .number(value) = self { value } else { nil } }
    public var array: [JSON]? { if case let .array(value) = self { value } else { nil } }
}

/// A record as CloudKit Web Services returns it.
public struct WebRecord: Sendable {
    public var recordName: String
    public var fields: [String: JSON]
    /// The iCloud user who created it: the same for every record a user writes, whatever the app says of itself.
    public var creator: String?
    public var created: Date?
    public var modified: Date?

    init?(_ json: JSON) {
        guard let name = json["recordName"]?.string, json["serverErrorCode"] == nil else { return nil }
        recordName = name
        var fields: [String: JSON] = [:]
        if case let .object(object)? = json["fields"] {
            for (key, value) in object { fields[key] = value["value"] }
        }
        self.fields = fields
        creator = json["created"]?["userRecordName"]?.string
        created = json["created"]?["timestamp"]?.number.map { Date(timeIntervalSince1970: $0 / 1000) }
        modified = json["modified"]?["timestamp"]?.number.map { Date(timeIntervalSince1970: $0 / 1000) }
    }
}

public enum CloudKitWebError: LocalizedError {
    case badKey
    case server(status: Int, path: String, body: String)
    case records([String])

    public var errorDescription: String? {
        switch self {
        case .badKey:
            "CLOUDKIT_PRIVATE_KEY is not a P-256 private key in PEM. Make it with "
                + "`openssl ecparam -name prime256v1 -genkey -noout -out eckey.pem`."
        case let .server(status, path, body): "CloudKit \(status) on \(path): \(body)"
        case let .records(errors): "CloudKit refused \(errors.count) record(s): \(errors.prefix(5).joined(separator: "; "))"
        }
    }
}

/// CloudKit Web Services on the public database, signed with a server-to-server key: the robot's only way in.
/// https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/
public struct CloudKitWeb: Sendable {
    public var container: String
    /// `development` or `production`.
    public var environment: String
    public var keyID: String
    private let key: P256.Signing.PrivateKey
    private let session: URLSession

    public init(container: String, environment: String, keyID: String, privateKeyPEM: String,
                session: URLSession = .shared) throws {
        self.container = container
        self.environment = environment
        self.keyID = keyID
        guard let key = try? P256.Signing.PrivateKey(pemRepresentation: privateKeyPEM) else {
            throw CloudKitWebError.badKey
        }
        self.key = key
        self.session = session
    }

    var basePath: String { "/database/1/\(container)/\(environment)/public" }

    // MARK: Requests

    /// Every page of a query, 200 records at a time.
    public func query(_ recordType: String, filters: [JSON] = [], desiredKeys: [String]? = nil) async throws
        -> [WebRecord] {
        var records: [WebRecord] = []
        var marker: String?
        repeat {
            var query: [String: JSON] = ["recordType": .string(recordType)]
            if !filters.isEmpty { query["filterBy"] = .array(filters) }
            var body: [String: JSON] = ["query": .object(query), "resultsLimit": .number(200)]
            if let desiredKeys { body["desiredKeys"] = .array(desiredKeys.map(JSON.string)) }
            if let marker { body["continuationMarker"] = .string(marker) }
            let response: JSON
            do {
                response = try await post("records/query", .object(body))
            } catch let CloudKitWebError.server(_, _, text) where text.contains("Did not find record type") {
                // A type CloudKit has not seen yet has no records.
                return []
            }
            records += (response["records"]?.array ?? []).compactMap(WebRecord.init)
            marker = response["continuationMarker"]?.string
        } while marker != nil
        return records
    }

    /// The records with these names that exist.
    public func lookup(_ names: [String], desiredKeys: [String]? = nil) async throws -> [WebRecord] {
        var body: [String: JSON] = ["records": .array(names.map { .object(["recordName": .string($0)]) })]
        if let desiredKeys { body["desiredKeys"] = .array(desiredKeys.map(JSON.string)) }
        let response = try await post("records/lookup", .object(body))
        return (response["records"]?.array ?? []).compactMap(WebRecord.init)
    }

    /// Writes these records whole (`forceReplace`), 200 at a time. Throws if CloudKit refuses any.
    public func replace(_ recordType: String, _ records: [(name: String, fields: [String: JSON])]) async throws {
        for start in stride(from: 0, to: records.count, by: 200) {
            let batch = records[start..<min(start + 200, records.count)]
            let operations: [JSON] = batch.map { record in
                .object(["operationType": .string("forceReplace"),
                         "record": .object(["recordName": .string(record.name),
                                            "recordType": .string(recordType),
                                            "fields": .object(record.fields)])])
            }
            let response = try await post("records/modify", .object(["operations": .array(operations),
                                                                      "atomic": .bool(false)]))
            let errors = (response["records"]?.array ?? []).compactMap { record -> String? in
                guard let code = record["serverErrorCode"]?.string else { return nil }
                return "\(record["recordName"]?.string ?? "?"): \(code) \(record["reason"]?.string ?? "")"
            }
            if !errors.isEmpty { throw CloudKitWebError.records(errors) }
        }
    }

    /// Uploads a file for an asset field and returns the value to save in that field.
    public func uploadAsset(_ data: Data, recordType: String, recordName: String, field: String) async throws -> JSON {
        let tokens = try await post("assets/upload", .object(["tokens": .array([.object([
            "recordType": .string(recordType), "recordName": .string(recordName), "fieldName": .string(field)
        ])])]))
        guard let url = tokens["tokens"]?.array?.first?["url"]?.string.flatMap(URL.init(string:)) else {
            throw CloudKitWebError.server(status: 0, path: "assets/upload", body: "no upload url")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        let (body, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200, let receipt = try JSONDecoder().decode(JSON.self, from: body)["singleFile"] else {
            throw CloudKitWebError.server(status: status, path: "asset upload", body: String(decoding: body, as: UTF8.self))
        }
        return receipt
    }

    /// The file of an asset field, as a lookup or a query returned it.
    public func download(_ asset: JSON) async throws -> Data? {
        guard let link = asset["downloadURL"]?.string?.replacingOccurrences(of: "${f}", with: "file"),
              let url = URL(string: link) else { return nil }
        let (data, response) = try await session.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return data
    }

    func post(_ operation: String, _ body: JSON) async throws -> JSON {
        let path = "\(basePath)/\(operation)"
        let data = try JSONEncoder().encode(body)
        var request = URLRequest(url: URL(string: "https://api.apple-cloudkit.com\(path)")!)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (header, value) in try signature(for: data, path: path, date: Date()) {
            request.setValue(value, forHTTPHeaderField: header)
        }
        let (body, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            throw CloudKitWebError.server(status: status, path: operation, body: String(decoding: body, as: UTF8.self))
        }
        return try JSONDecoder().decode(JSON.self, from: body)
    }

    /// The three headers of a server-to-server request: the date, and the ECDSA signature of
    /// `date:base64(SHA-256(body)):path`.
    func signature(for body: Data, path: String, date: Date) throws -> [String: String] {
        let stamp = ISO8601DateFormatter().string(from: date)
        let message = "\(stamp):\(Data(SHA256.hash(data: body)).base64EncodedString()):\(path)"
        let signature = try key.signature(for: Data(message.utf8))
        return ["X-Apple-CloudKit-Request-KeyID": keyID,
                "X-Apple-CloudKit-Request-ISO8601Date": stamp,
                "X-Apple-CloudKit-Request-SignatureV1": signature.derRepresentation.base64EncodedString()]
    }

    /// The public key, to check a signature in the tests.
    var publicKey: P256.Signing.PublicKey { key.publicKey }
}

public extension JSON {
    /// A filter of a query on a field: `EQUALS`, `IN`, `GREATER_THAN`…
    static func filter(_ field: String, _ comparator: String, _ value: JSON, type: String? = nil) -> JSON {
        var fieldValue: [String: JSON] = ["value": value]
        if let type { fieldValue["type"] = .string(type) }
        return .object(["fieldName": .string(field), "comparator": .string(comparator), "fieldValue": .object(fieldValue)])
    }

    /// A filter on when records were last changed.
    static func modified(after date: Date) -> JSON {
        .object(["systemFieldName": .string("modifiedTimestamp"), "comparator": .string("GREATER_THAN"),
                 "fieldValue": .object(["value": .number((date.timeIntervalSince1970 * 1000).rounded(.down)),
                                        "type": .string("TIMESTAMP")])])
    }

    static func timestamp(_ date: Date) -> JSON {
        .object(["value": .number((date.timeIntervalSince1970 * 1000).rounded(.down)), "type": .string("TIMESTAMP")])
    }

    static func field(_ value: JSON) -> JSON { .object(["value": value]) }
}
