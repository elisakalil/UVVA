import Core
import Foundation
import OSLog
import Storage
import SwiftData

@MainActor
final class ContentLoader {
    nonisolated static let versionKey = "content.version"

    private nonisolated let questionsTask: Task<Void, Error>
    /// The recipes and lessons of the bundle, then the wines of the public catalog: the whole snapshot the first time,
    /// which the tabs wait for; after, the day's changes, which they do not wait for (ARCHITECTURE §4.1).
    /// Returns whether it already synced the public catalog (the first time, when the phone has none).
    private nonisolated let catalogTask: Task<Bool, Error>
    /// The day's changes of the public catalog, once the phone has one. The tabs wait for them under the Splash, up
    /// to a limit, so they are not fetched and written while the Home is in use.
    private nonisolated let dailySyncTask: Task<Void, Never>
    /// Lets the catalog import go. It waits for this, so it doesn't compete with opening the stores, the glass
    /// textures and the first reads while the Splash is on screen (ONB-R01).
    private nonisolated let catalogGate: AsyncStream<Void>.Continuation

    init(container: ModelContainer, stores: AppStores) throws {
        guard let source = ContentSource(bundle: .main) else {
            throw ContentError.missingManifest
        }

        let version = UserDefaults.standard.string(forKey: Self.versionKey)

        let questions = Task.detached(priority: .utility) {
            try await ContentImporter(modelContainer: container)
                .importQuestionsIfNeeded(
                    from: source,
                    currentVersion: version
                )
        }

        questionsTask = questions

        let (gate, opening) = AsyncStream<Void>.makeStream()
        catalogGate = opening

        let catalog = Task.detached(priority: .utility) {
            try await questions.value
            // Ends without a value when the task is cancelled; the check below then throws.
            for await _ in gate { break }
            try Task.checkCancellation()

            let importedVersion = try await ContentImporter(
                modelContainer: container
            ).importCatalogIfNeeded(
                from: source,
                currentVersion: version
            )

            try Task.checkCancellation()

            if let importedVersion {
                UserDefaults.standard.set(
                    importedVersion,
                    forKey: Self.versionKey
                )
            }

            let sync = stores.catalogSync
            try await sync.restorePrevalence()
            guard try await sync.hasCatalog() else {
                try await Self.syncCatalog(stores)
                return true
            }
            return false
        }
        catalogTask = catalog

        dailySyncTask = Task.detached(priority: .utility) {
            guard let synced = try? await catalog.value, !synced, !Task.isCancelled else { return }
            do {
                try await Self.syncCatalog(stores)
            } catch {
                Self.logger.error("Catalog sync failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private nonisolated static let logger = Logger(subsystem: "app.uvva", category: "catalog")

    /// The wines in the Cellar or rated never leave the phone; the palate chooses which wines a full phone keeps.
    private nonisolated static func syncCatalog(_ stores: AppStores) async throws {
        let rated = Rating.verdicts(in: try await stores.maps.history()).keys
        let protected = try await stores.cellar.wineKeys().union(rated)
        let map = try await stores.maps.currentMap()
        try await stores.catalogSync.sync(protecting: protected, map: map)
    }

    func waitForQuestions() async throws {
        try await questionsTask.value
        try Task.checkCancellation()
    }

    /// Starts the catalog import, once the first screen after the Splash is up. Calling it again does nothing.
    nonisolated func startCatalogImport() {
        catalogGate.yield()
        catalogGate.finish()
    }

    /// The Splash has faded out over the Onboarding or the Quiz: the catalog import may start.
    nonisolated func screenRevealed() {
        startCatalogImport()
    }

    func waitUntilReady() async throws {
        startCatalogImport()
        _ = try await catalogTask.value
        try Task.checkCancellation()
    }

    /// The day's catalog changes are in (or failed, offline). Starts the catalog import if it has not started.
    nonisolated func waitForDailySync() async {
        startCatalogImport()
        await dailySyncTask.value
    }

    nonisolated func cancel() {
        questionsTask.cancel()
        catalogTask.cancel()
        catalogGate.finish()
        dailySyncTask.cancel()
    }

    func stop() async {
        cancel()
        _ = try? await questionsTask.value
        _ = try? await catalogTask.value
        await dailySyncTask.value
    }

    static func openStores() async throws -> ModelContainer {
        try await Task.detached(priority: .userInitiated) {
            try makeContainer()
        }.value
    }

    private nonisolated static func makeContainer() throws -> ModelContainer {
        if let container = try? AppStore.makeContainer() {
            return container
        }

        try? FileManager.default.removeItem(
            at: ContentStore.defaultURL.deletingLastPathComponent()
        )
        UserDefaults.standard.removeObject(forKey: versionKey)

        return try AppStore.makeContainer()
    }

    private enum ContentError: LocalizedError {
        case missingManifest

        var errorDescription: String? {
            String(localized: "The bundled content manifest could not be found.")
        }
    }
}
