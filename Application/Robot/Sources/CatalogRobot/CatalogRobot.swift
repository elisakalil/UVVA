import CryptoKit
import Core
import Foundation
import Match

/// What the robot remembers between runs, in the snapshot record's `state` asset.
public struct RobotState: Codable, Equatable, Sendable {
    /// When the last finished run started: the contributions changed after it are counted again.
    public var builtAt: Date?
    public var entries: [String: CommunityEntry]
    /// The hash of each `CatalogWine` as last written, to write only what changed.
    public var published: [String: String]

    public init(builtAt: Date? = nil, entries: [String: CommunityEntry] = [:], published: [String: String] = [:]) {
        self.builtAt = builtAt
        self.entries = entries
        self.published = published
    }
}

/// One run of the robot (ARCHITECTURE §4.1, §4.3):
///
/// 1. Reads its state and the contributions changed since the last run, then every contribution of those wines.
/// 2. Counts them (`ContributionRules`, `CatalogMerge`) and builds the catalog: the seed, enriched, and the wines the
///    users made known.
/// 3. Writes the `CatalogWine` that changed (and marks `removed` those that left), then the `CatalogSnapshot`.
///
/// A run that stops half way leaves the last snapshot as it was; the next run writes again what changed.
public struct CatalogRobot: Sendable {
    public var cloud: CloudKitWeb
    /// `Data/UVVAWines.json` as `pack_content.py --seed` checks and packs it.
    public var seed: [CatalogWineData]
    public var portugueseTexts: [String: String]
    /// Prints what it would write, and writes nothing.
    public var dryRun: Bool
    public var log: @Sendable (String) -> Void

    public init(cloud: CloudKitWeb, seed: [CatalogWineData], dryRun: Bool = false,
                portugueseTexts: [String: String] = [:],
                log: @escaping @Sendable (String) -> Void = { print($0) }) {
        self.cloud = cloud
        self.seed = seed
        self.dryRun = dryRun
        self.portugueseTexts = portugueseTexts
        self.log = log
    }

    private typealias Snapshot = CatalogSchema.Snapshot
    private typealias Fields = CatalogSchema.Contribution

    public func run(now: Date = Date()) async throws {
        var state = try await loadState()
        log("State: \(state.entries.count) community wines, \(state.published.count) published, "
            + "last run \(state.builtAt.map { "\($0)" } ?? "never")")

        // 1. The contributions changed since the last run, and all the others of the same wines.
        let changed = try await cloud.query(Fields.type,
                                            filters: [.modified(after: state.builtAt ?? .distantPast)],
                                            desiredKeys: [Fields.wineKey])
        let keys = Set(changed.compactMap { $0.fields[Fields.wineKey]?.string })
        log("Contributions changed: \(changed.count), on \(keys.count) wines")
        var contributions: [Contribution] = []
        for batch in Array(keys).sorted().chunked(into: 100) {
            contributions += try await cloud.query(
                Fields.type,
                filters: [.filter(Fields.wineKey, "IN", .array(batch.map(JSON.string)), type: "STRING_LIST")]
            ).compactMap(Contribution.init)
        }

        // 2. The entries of those wines, and the catalog.
        let accepted = Dictionary(grouping: ContributionRules.accepted(contributions, now: now), by: \.wineKey)
        log("Accepted: \(accepted.values.reduce(0) { $0 + $1.count }) of \(contributions.count)")
        for key in keys {
            state.entries[key] = CatalogMerge.entry(accepted[key] ?? [], previous: state.entries[key])
        }
        let catalog = CatalogMerge.catalog(seed: seed, entries: state.entries)
        let community = catalog.count - Set(seed.map(\.id)).intersection(catalog.map(\.id)).count
        log("Catalog: \(catalog.count) wines (\(community) made known by users)")

        // 3. The wines that changed, then the snapshot.
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        var hashes: [String: String] = [:]
        var writes: [(name: String, fields: [String: JSON])] = []
        for wine in catalog {
            let json = try encoder.encode(wine)
            let hash = Self.hash(json)
            hashes[wine.id] = hash
            guard state.published[wine.id] != hash else { continue }
            writes.append((wine.id, [CatalogSchema.Wine.data: .field(.string(String(decoding: json, as: UTF8.self))),
                                     CatalogSchema.Wine.status: .field(.string(CatalogSchema.Wine.active)),
                                     CatalogSchema.Wine.tokens: .field(.array(wine.searchTokens.map(JSON.string)))]))
        }
        let removed = Set(state.published.keys).subtracting(hashes.keys).sorted()
        writes += removed.map { ($0, [CatalogSchema.Wine.status: .field(.string(CatalogSchema.Wine.removed)),
                                      CatalogSchema.Wine.data: .field(.string("")),
                                      CatalogSchema.Wine.tokens: .field(.array([]))]) }
        log("To write: \(writes.count - removed.count) wines, \(removed.count) removed")

        state.builtAt = now
        state.published = hashes
        let wines = try Self.compress(encoder.encode(CatalogWinesFile(wines: catalog)))
        let sourceTexts = Set(catalog.flatMap { wine in
            wine.pairings + [wine.note, wine.howToServe, wine.originInsight, wine.appellationInsight].compactMap { $0 }
        })
        let translations = portugueseTexts.filter {
            sourceTexts.contains($0.key) && !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let translatedFile = translations.isEmpty ? nil : try Self.compress(encoder.encode(translations))
        log("pt-BR: \(translations.count) of \(sourceTexts.count) distinct texts translated")
        let stateFile = try Self.compress(encoder.encode(state))
        let prevalence = QualityPrevalence.measure(catalog.map(\.wine))
        guard !dryRun else {
            log("Dry run: nothing written. Snapshot \(wines.count) bytes, state \(stateFile.count) bytes, "
                + "prevalence \(prevalence.map { "\($0)" } ?? "none")")
            return
        }
        try await cloud.replace(CatalogSchema.Wine.type, writes)

        let winesAsset = try await cloud.uploadAsset(wines, recordType: Snapshot.type, recordName: Snapshot.recordName,
                                                     field: Snapshot.wines)
        let stateAsset = try await cloud.uploadAsset(stateFile, recordType: Snapshot.type,
                                                     recordName: Snapshot.recordName, field: Snapshot.state)
        var fields: [String: JSON] = [
            Snapshot.version: .field(.string(String(Self.hash(wines + (translatedFile ?? Data())).prefix(16)))),
            Snapshot.builtAt: .timestamp(now),
            Snapshot.wineCount: .field(.number(Double(catalog.count))),
            Snapshot.wines: .field(winesAsset),
            Snapshot.state: .field(stateAsset)
        ]
        if let translatedFile {
            let asset = try await cloud.uploadAsset(translatedFile, recordType: Snapshot.type,
                                                    recordName: Snapshot.recordName, field: Snapshot.portugueseTexts)
            fields[Snapshot.portugueseTexts] = .field(asset)
        }
        if let prevalence {
            fields[Snapshot.prevalence] = .field(.string(String(decoding: try encoder.encode(prevalence), as: UTF8.self)))
        }
        try await cloud.replace(Snapshot.type, [(Snapshot.recordName, fields)])
        log("Snapshot published: \(catalog.count) wines")
    }

    private func loadState() async throws -> RobotState {
        guard let record = try await cloud.lookup([Snapshot.recordName], desiredKeys: [Snapshot.state]).first,
              let asset = record.fields[Snapshot.state],
              let data = try await cloud.download(asset) else { return RobotState() }
        return try JSONDecoder().decode(RobotState.self, from: Self.decompress(data))
    }

    static func hash(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    /// zlib, as the app reads it (`NSData.decompressed(using: .zlib)`).
    static func compress(_ data: Data) throws -> Data {
        try (data as NSData).compressed(using: .zlib) as Data
    }

    static func decompress(_ data: Data) throws -> Data {
        try (data as NSData).decompressed(using: .zlib) as Data
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}
