import Foundation
import Observation
import OSLog
import Storage
import SwiftData

/// Opens the stores and copies the bundled content into the Content store at launch, while the Splash and the Onboarding run
/// (ONB-R01, ARCHITECTURE §2.2). The version imported is kept in UserDefaults; a new app version with new
/// content imports again.
@MainActor @Observable
final class ContentLoader {
    nonisolated static let versionKey = "content.version"

    let container: ModelContainer
    /// The stage running now; nil before the first and after the last.
    private(set) var stage: ContentImportStage?
    private(set) var isReady = false

    private let logger = Logger(subsystem: "app.uvva", category: "content")

    init(container: ModelContainer) {
        self.container = container
    }

    /// Opens the stores off the main thread. The Personal store sets up its iCloud sync as it opens, which on a
    /// fresh install takes seconds; done on the main thread, it held the system's plain launch screen until it finished.
    static func openStores() async -> ModelContainer {
        await Task.detached(priority: .userInitiated) { makeContainer() }.value
    }

    func load() async {
        guard let source = ContentSource(bundle: .main) else {
            logger.fault("Content manifest missing from the bundle")
            return
        }
        let defaults = UserDefaults.standard
        let container = container
        let current = defaults.string(forKey: Self.versionKey)
        let start = Date()
        do {
            // Created off the main actor, so the import runs on a background context.
            let version = try await Task.detached(priority: .utility) {
                try await ContentImporter(modelContainer: container)
                    .importIfNeeded(from: source, currentVersion: current) { stage in
                        Task { @MainActor [weak self] in self?.stage = stage }
                    }
            }.value
            if let version {
                defaults.set(version, forKey: Self.versionKey)
                logger.info("Imported content \(version) in \(Date().timeIntervalSince(start), format: .fixed(precision: 2)) s")
            }
            stage = nil
            isReady = true
        } catch {
            logger.error("Content import failed: \(error.localizedDescription)")
        }
    }

    /// The Content and the Personal stores. The Content store is rebuilt from the bundle, so one that cannot open
    /// (a changed schema during development) is deleted and created again; the Personal store is never deleted.
    private nonisolated static func makeContainer() -> ModelContainer {
        if let container = try? AppStore.makeContainer() { return container }
        try? FileManager.default.removeItem(at: ContentStore.defaultURL.deletingLastPathComponent())
        UserDefaults.standard.removeObject(forKey: Self.versionKey)
        do {
            return try AppStore.makeContainer()
        } catch {
            fatalError("Stores cannot open: \(error)")
        }
    }
}
