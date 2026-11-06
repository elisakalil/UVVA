import Foundation
import Storage
import SwiftData

@MainActor
final class ContentLoader {
    nonisolated static let versionKey = "content.version"

    private nonisolated let questionsTask: Task<Void, Error>
    private nonisolated let catalogTask: Task<Void, Error>
    /// Lets the catalog import go. It waits for this, so it doesn't compete with opening the stores, the glass
    /// textures and the first reads while the Splash is on screen (ONB-R01).
    private nonisolated let catalogGate: AsyncStream<Void>.Continuation

    init(container: ModelContainer) throws {
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

        catalogTask = Task.detached(priority: .utility) {
            try await questions.value
            // Ends without a value when the task is cancelled; the check below then throws.
            for await _ in gate { break }
            try Task.checkCancellation()

            let protected = try await CellarStore(
                modelContainer: container
            ).wineKeys()

            let importedVersion = try await ContentImporter(
                modelContainer: container
            ).importCatalogIfNeeded(
                from: source,
                currentVersion: version,
                protectedWineKeys: protected
            )

            try Task.checkCancellation()

            if let importedVersion {
                UserDefaults.standard.set(
                    importedVersion,
                    forKey: Self.versionKey
                )
            }
        }
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

    func waitUntilReady() async throws {
        startCatalogImport()
        try await catalogTask.value
        try Task.checkCancellation()
    }

    nonisolated func cancel() {
        questionsTask.cancel()
        catalogTask.cancel()
        catalogGate.finish()
    }

    func stop() async {
        cancel()
        _ = try? await questionsTask.value
        _ = try? await catalogTask.value
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
            "The bundled content manifest could not be found."
        }
    }
}
