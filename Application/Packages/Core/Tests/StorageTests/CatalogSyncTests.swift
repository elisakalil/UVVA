import Core
import Foundation
import Match
import SwiftData
import Synchronization
import Testing
@testable import Storage

/// The public catalog as a test sets it up.
final class FakeCatalogCloud: CatalogCloudService {
    struct State {
        var info: CatalogSnapshotInfo?
        var snapshot: [CatalogWineData] = []
        var changes: [CatalogChange] = []
        var calls: [String] = []
        var contributed: [String: [CatalogWineData]] = [:]
        var refused: Set<String> = []
    }

    let state = Mutex(State())

    func snapshotInfo() async throws -> CatalogSnapshotInfo? {
        state.withLock { $0.calls.append("info"); return $0.info }
    }

    func snapshotWines() async throws -> [CatalogWineData] {
        state.withLock { $0.calls.append("snapshot"); return $0.snapshot }
    }

    func changes(since date: Date) async throws -> [CatalogChange] {
        state.withLock { state in
            state.calls.append("changes")
            return state.changes.filter { $0.modifiedAt > date }
        }
    }

    func wines(sharing tokens: Set<String>) async throws -> [CatalogWineData] {
        state.withLock { state in
            state.snapshot.filter { !Set($0.searchTokens).isDisjoint(with: tokens) }
        }
    }

    func contribute(_ wines: [CatalogWineData], userID: String) async throws -> Set<String> {
        state.withLock { state in
            let kept = wines.filter { !state.refused.contains($0.id) }
            state.contributed[userID, default: []] += kept
            return Set(kept.map(\.id))
        }
    }
}

struct CatalogSyncTests {
    let container: ModelContainer
    let cloud = FakeCatalogCloud()
    let writer: CatalogWriter
    let sync: CatalogSync
    let builtAt = Date(timeIntervalSince1970: 1_800_000_000)

    init() throws {
        container = try AppStore.makeInMemoryContainer()
        writer = CatalogWriter(modelContainer: container)
        sync = CatalogSync(cloud: cloud, writer: writer, cap: 4)
        let info = CatalogSnapshotInfo(version: "s1", builtAt: builtAt, wineCount: 2, prevalence: .packed)
        let snapshot = try Self.wines([("a", 3), ("b", 7)])
        cloud.state.withLock {
            $0.info = info
            $0.snapshot = snapshot
        }
    }

    static func wines(_ specs: [(String, Double)]) throws -> [CatalogWineData] {
        var fixture = ContentFixture()
        fixture.wines = specs.map { ContentFixture.wine($0.0, name: $0.0, vintage: nil, acidity: $0.1) }
        return try fixture.catalogWines()
    }

    private func keys() throws -> Set<String> {
        Set(try ModelContext(container).fetch(FetchDescriptor<WineEntity>()).map(\.wineKey))
    }

    private func sources() throws -> [String: String] {
        Dictionary(uniqueKeysWithValues: try ModelContext(container).fetch(FetchDescriptor<WineEntity>())
            .map { ($0.wineKey, $0.source) })
    }

    let scanned = Wine(id: "casa-nova-tinto", name: "Tinto", producer: "Casa Nova", type: "Red", origin: "Douro",
                       profile: PalateMap([.acidity: 5]))

    // MARK: First sync

    @Test func firstSync_bringsTheWholeSnapshot_andReplacesTheOldBundle() async throws {
        let context = ModelContext(container)
        context.insert(WineEntity(wineKey: "old-bundle", source: "bundle"))
        context.insert(WineEntity(wineKey: "in-cellar", source: "bundle"))
        try context.save()
        try await CatalogStore(modelContainer: container).addScanned(scanned)
        #expect(try await sync.hasCatalog())

        try await sync.sync(protecting: ["in-cellar"], map: nil, now: builtAt)

        #expect(try keys() == ["a", "b", "in-cellar", scanned.id])
        #expect(try sources()["a"] == "catalog")
        #expect(try sources()[scanned.id] == "scanned")
        let state = try await writer.state()
        #expect(state.lastChange == builtAt)
        #expect(state.snapshotVersion == "s1")
        #expect(state.prevalence == .packed)
    }

    @Test func firstSync_withoutASnapshot_throws_soTheTabsCanAskToTryAgain() async throws {
        cloud.state.withLock { $0.info = nil }
        #expect(try await !sync.hasCatalog())
        await #expect(throws: CatalogCloudError.self) {
            try await sync.sync(protecting: [], map: nil)
        }
    }

    // MARK: Daily changes

    @Test func aSecondSync_theSameDay_asksNothing() async throws {
        try await sync.sync(protecting: [], map: nil, now: builtAt)
        cloud.state.withLock { $0.calls = [] }
        try await sync.sync(protecting: [], map: nil, now: builtAt.addingTimeInterval(3600))
        #expect(cloud.state.withLock { $0.calls } == [])
    }

    @Test func theNextDay_theChangesComeIn_andWinesThatLeftGo_unlessProtected() async throws {
        try await sync.sync(protecting: [], map: nil, now: builtAt)
        let changed = try Self.wines([("a", 9), ("c", 1)])
        cloud.state.withLock {
            $0.calls = []
            $0.changes = [CatalogChange(wineKey: "a", wine: changed[0], modifiedAt: builtAt.addingTimeInterval(60)),
                          CatalogChange(wineKey: "c", wine: changed[1], modifiedAt: builtAt.addingTimeInterval(120)),
                          CatalogChange(wineKey: "b", wine: nil, modifiedAt: builtAt.addingTimeInterval(180))]
        }
        try await sync.sync(protecting: [], map: nil, now: builtAt.addingTimeInterval(25 * 3600))

        #expect(cloud.state.withLock { $0.calls } == ["info", "changes"])
        #expect(try keys() == ["a", "c"])
        let a = try #require(try await CatalogStore(modelContainer: container).wines(keys: ["a"])["a"])
        #expect(a.profile[.acidity] == 9)
        #expect(try await writer.state().lastChange == builtAt.addingTimeInterval(180))
    }

    @Test func aWineThatLeftTheCatalog_staysWhileItIsInTheCellar() async throws {
        try await sync.sync(protecting: [], map: nil, now: builtAt)
        cloud.state.withLock {
            $0.changes = [CatalogChange(wineKey: "b", wine: nil, modifiedAt: builtAt.addingTimeInterval(60))]
        }
        try await sync.sync(protecting: ["b"], map: nil, now: builtAt.addingTimeInterval(25 * 3600))
        #expect(try keys() == ["a", "b"])
    }

    // MARK: A full phone

    @Test func overTheCap_theWinesFurthestFromThePalateLeave_butNotScannedOrProtectedOnes() async throws {
        let many = try Self.wines([("a", 9), ("b", 8), ("c", 1), ("d", 0), ("e", 2)])
        cloud.state.withLock { $0.snapshot = many }
        try await CatalogStore(modelContainer: container).addScanned(scanned)
        let palate = PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, $0 == .acidity ? 9 : 5) }))

        try await sync.sync(protecting: ["d"], map: palate, now: builtAt)

        #expect(try keys() == ["a", "b", "d", scanned.id])
    }

    @Test func overTheCap_withoutAPalate_nothingLeaves() async throws {
        let many = try Self.wines([("a", 9), ("b", 8), ("c", 1), ("d", 0), ("e", 2)])
        cloud.state.withLock { $0.snapshot = many }
        try await sync.sync(protecting: [], map: nil, now: builtAt)
        #expect(try keys().count == 5)
    }

    // MARK: Contributions

    @Test func theReadingsQueued_areSent_andLeaveTheQueue() async throws {
        try await sync.sync(protecting: [], map: nil, now: builtAt)
        let store = CatalogStore(modelContainer: container)
        try await store.addScanned(scanned)
        try await sync.sendContributions(userID: "user-1")
        #expect(cloud.state.withLock { $0.contributed["user-1"]?.map(\.id) } == [scanned.id])
        #expect(try await writer.pendingContributions(limit: 10).isEmpty)
    }

    @Test func aReadingCloudKitRefuses_waitsForTheNextTime() async throws {
        cloud.state.withLock { $0.refused = [scanned.id] }
        try await CatalogStore(modelContainer: container).addScanned(scanned)
        try await sync.sendContributions(userID: "user-1")
        #expect(try await writer.pendingContributions(limit: 10).map(\.wine.id) == [scanned.id])
    }

    @Test func winesScannedBeforeThePublicCatalog_areSentOnce() async throws {
        try await CatalogStore(modelContainer: container).addScanned(scanned)
        // As on a phone that scanned before contributions existed.
        try await writer.clearPending()
        try await sync.sendContributions(userID: "user-1")
        try await sync.sendContributions(userID: "user-1")
        #expect(cloud.state.withLock { $0.contributed["user-1"]?.map(\.id) } == [scanned.id])
    }

    @Test func anAccountDeleted_sendsNothingItRead() async throws {
        try await sync.sendContributions(userID: "user-1")
        try await CatalogStore(modelContainer: container).addScanned(scanned)
        try await sync.forgetContributions()
        try await sync.sendContributions(userID: "user-2")
        #expect(cloud.state.withLock { $0.contributed["user-2"] } == nil)
    }

    // MARK: A label the phone does not have

    @Test func aLabelNotOnThePhone_isFoundInThePublicCatalog_andStays() async throws {
        let wines = try Self.wines([("bravo", 7), ("charlie", 2)])
        cloud.state.withLock { $0.snapshot = wines }
        let store = CatalogStore(modelContainer: container, cloud: cloud)
        let found = try await store.publicWines(sharing: ["bravo"])
        #expect(found.map(\.id) == ["bravo"])
        #expect(try keys() == ["bravo"])
        #expect(try sources()["bravo"] == "catalog")
    }
}

struct CatalogSnapshotFileTests {
    @Test func theRobotsFile_isReadAsItWasWritten() throws {
        let wines = try CatalogSyncTests.wines([("a", 3)])
        let json = try JSONEncoder().encode(CatalogWinesFile(wines: wines))
        let compressed = try (json as NSData).compressed(using: .zlib) as Data
        #expect(try CloudKitCatalogService.decodeWines(compressed) == wines)
    }
}
