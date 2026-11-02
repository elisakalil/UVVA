import Foundation
import SwiftData

/// The Content store: wines, recipes, lessons, glossary and Quiz questions (ARCHITECTURE §2.2).
/// It is rebuilt from the bundle and the public database, so it stays out of iCloud and of the device backup.
public enum ContentStore {
    public static let models: [any PersistentModel.Type] = [
        WineEntity.self, RecipeEntity.self, ModuleEntity.self, LessonEntity.self,
        GlossaryTermEntity.self, QuizQuestionEntity.self
    ]

    /// `Application Support/Content/Content.store`.
    public static var defaultURL: URL {
        URL.applicationSupportDirectory.appending(path: "Content/Content.store")
    }

    /// The configuration for this store. In memory when `url` is nil (tests and previews).
    public static func configuration(url: URL?) -> ModelConfiguration {
        if let url {
            ModelConfiguration("Content", schema: Schema(models), url: url, cloudKitDatabase: .none)
        } else {
            ModelConfiguration("Content", schema: Schema(models), isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        }
    }

    public static func makeContainer(url: URL? = defaultURL) throws -> ModelContainer {
        if let url { try prepareFolder(for: url) }
        return try ModelContainer(for: Schema(models), configurations: [configuration(url: url)])
    }

    /// Creates the store's folder and keeps it out of the device backup.
    static func prepareFolder(for url: URL) throws {
        var folder = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try folder.setResourceValues(values)
    }
}
