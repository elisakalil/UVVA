import Foundation
import Storage
import SwiftData

@MainActor
final class ContentLoader {
    nonisolated static let versionKey = "content.version"

    private nonisolated let questionsTask: Task<Void, Error>
    private nonisolated let catalogTask: Task<Void, Error>

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

        catalogTask = Task.detached(priority: .utility) {
            try await questions.value
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

    func waitUntilReady() async throws {
        try await catalogTask.value
        try Task.checkCancellation()
    }

    nonisolated func cancel() {
        questionsTask.cancel()
        catalogTask.cancel()
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
