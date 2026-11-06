import Core
import Storage
import SwiftData

/// The repositories of the app. A `@ModelActor` runs on the queue it is created on, so these are made off the
/// main thread: made on it, every read waited there for the content import holding the store, and the first
/// screen stayed on the plain launch colour until the import finished.
/// The CloudKit social service is made here too: `CKContainer(identifier:)` talks to `cloudd` synchronously, and on
/// the first launch, while SwiftData sets up the Personal store's iCloud mirroring, that held the main thread and froze
/// the Splash.
struct AppStores: Sendable {
    let maps: PalateMapStore
    let questions: QuizQuestionStore
    let profiles: ProfileStore
    let catalog: CatalogStore
    let reminders: ReminderStore
    let cellar: CellarStore
    let learning: LearningStore
    let social: any SocialService

    static func make(container: ModelContainer) async -> AppStores {
        await Task.detached(priority: .userInitiated) {
            AppStores(maps: PalateMapStore(modelContainer: container),
                      questions: QuizQuestionStore(modelContainer: container),
                      profiles: ProfileStore(modelContainer: container),
                      catalog: CatalogStore(modelContainer: container),
                      reminders: ReminderStore(modelContainer: container),
                      cellar: CellarStore(modelContainer: container),
                      learning: LearningStore(modelContainer: container),
                      social: CloudKitSocialService())
        }.value
    }
}
