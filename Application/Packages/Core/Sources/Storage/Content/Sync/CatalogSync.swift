import Core
import Foundation
import Match
import OSLog

/// Keeps the phone's copy of the public catalog and sends the user's readings to it (ARCHITECTURE §4.1, §4.3).
///
/// - The first time, the whole snapshot the robot publishes; then, at most once a day, the `CatalogWine` changed
///   since, which brings the wines other users made known and takes off those that left the catalog.
/// - Over `CatalogSchema.deviceCap` wines, those furthest from the palate leave the phone.
/// - Every label read is queued (`CatalogStore.addScanned`) and sent as the user's `WineContribution`.
public final class CatalogSync: Sendable {
    private static let logger = Logger(subsystem: "app.uvva", category: "catalog-texts")

    private let cloud: any CatalogCloudService
    private let writer: CatalogWriter
    private let texts: CatalogTextCache?
    private let cap: Int
    private let interval: TimeInterval

    public init(cloud: any CatalogCloudService, writer: CatalogWriter, cap: Int = CatalogSchema.deviceCap,
                interval: TimeInterval = 24 * 3600, texts: CatalogTextCache? = nil) {
        self.cloud = cloud
        self.writer = writer
        self.texts = texts
        self.cap = cap
        self.interval = interval
    }

    /// Whether the phone has wines yet, from a snapshot or from the catalog the app once shipped with: without, the
    /// Home has none to show and the first sync must be waited for.
    public func hasCatalog() async throws -> Bool {
        if try await writer.state().lastChange != nil { return true }
        return try await writer.wineCount() > 0
    }

    /// Makes the last snapshot's shares the ones every certificate uses (CELLAR-R30), before any network.
    public func restorePrevalence() async throws {
        if let prevalence = try await writer.state().prevalence { QualityPrevalence.use(prevalence) }
    }

    /// The first time, waits for the whole catalog and throws if it cannot get it; after, asks for the changes at
    /// most once every `interval`.
    /// - Parameters:
    ///   - protecting: the wines that never leave the phone (in the Cellar or rated).
    ///   - map: the user's palate, to choose the wines a full phone keeps.
    public func sync(protecting protected: Set<String>, map: PalateMap?, now: Date = Date()) async throws {
        var state = try await writer.state()
        let first = state.lastChange == nil
        if !first, let lastCheck = state.lastCheck, now.timeIntervalSince(lastCheck) < interval {
            if let version = state.snapshotVersion { await syncTexts(version: version) }
            return
        }

        guard let info = try await cloud.snapshotInfo() else {
            if first { throw CatalogCloudError.noSnapshot }
            return
        }
        if let lastChange = state.lastChange {
            let changes = try await cloud.changes(since: lastChange)
            try await writer.apply(changes, protecting: protected)
            state.lastChange = max(lastChange, changes.map(\.modifiedAt).max() ?? lastChange)
        } else {
            let wines = try await cloud.snapshotWines()
            guard !wines.isEmpty else { throw CatalogCloudError.noSnapshot }
            try await writer.replaceAll(with: wines, protecting: protected)
            state.lastChange = info.builtAt
        }
        try await writer.trim(to: cap, closestTo: map, protecting: protected)

        state.lastCheck = now
        state.snapshotVersion = info.version
        if let prevalence = info.prevalence {
            state.prevalence = prevalence
            QualityPrevalence.use(prevalence)
        }
        try await writer.save(state)
        await syncTexts(version: info.version)
    }

    private func syncTexts(version: String) async {
        guard let texts, texts.version != version else { return }
        do {
            let translations = try await cloud.portugueseTexts()
            try Task.checkCancellation()
            try texts.save(translations, version: version)
        } catch is CancellationError {
            return
        } catch {
            Self.logger.error("Catalog translations could not be refreshed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Sends every reading waiting, as this user's contributions. Without an iCloud account or a network it throws,
    /// and they wait for the next time.
    public func sendContributions(userID: String) async throws {
        try await writer.queueEarlierScans()
        while true {
            let pending = try await writer.pendingContributions(limit: 200)
            guard !pending.isEmpty else { return }
            let saved = try await cloud.contribute(pending.map(\.wine), userID: userID)
            try await writer.removeSent(pending.filter { saved.contains($0.wine.id) })
            // What CloudKit refused stays queued for the next time.
            guard saved.count == pending.count else { return }
        }
    }

    /// An account deleted: nothing it read is sent from now on.
    public func forgetContributions() async throws {
        try await writer.clearPending()
    }
}
