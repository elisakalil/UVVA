import Foundation
import SwiftData

/// The one ModelContainer of the app, with the Content and the Personal stores side by side (ARCHITECTURE §2).
/// There are no relationships between the two.
public enum AppStore {
    public static func makeContainer(contentURL: URL? = ContentStore.defaultURL,
                                     personalURL: URL? = PersonalStore.defaultURL) throws -> ModelContainer {
        if let contentURL { try ContentStore.prepareFolder(for: contentURL) }
        if let personalURL {
            try FileManager.default.createDirectory(at: personalURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
        }
        return try ModelContainer(
            for: Schema(ContentStore.models + PersonalStore.models),
            configurations: [ContentStore.configuration(url: contentURL), PersonalStore.configuration(url: personalURL)]
        )
    }

    /// Both stores in memory, without CloudKit.
    public static func makeInMemoryContainer() throws -> ModelContainer {
        try makeContainer(contentURL: nil, personalURL: nil)
    }
}
