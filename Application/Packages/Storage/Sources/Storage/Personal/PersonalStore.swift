import Foundation
import SwiftData

/// The Personal store: profile, map, ratings, Cellar, progress (ARCHITECTURE §2.1).
/// SwiftData syncs it with the user's private CloudKit database.
public enum PersonalStore {
    public static let cloudKitContainer = "iCloud.app.uvva"

    public static let models: [any PersistentModel.Type] = [ProfileEntity.self, PalateMapEntity.self, ReminderEntity.self]

    /// `Application Support/Personal/Personal.store`.
    public static var defaultURL: URL {
        URL.applicationSupportDirectory.appending(path: "Personal/Personal.store")
    }

    /// In memory and without CloudKit when `url` is nil (tests and previews).
    public static func configuration(url: URL?) -> ModelConfiguration {
        if let url {
            ModelConfiguration("Personal", schema: Schema(models), url: url,
                               cloudKitDatabase: .private(cloudKitContainer))
        } else {
            ModelConfiguration("Personal", schema: Schema(models), isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        }
    }
}
