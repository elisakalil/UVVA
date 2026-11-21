import Core
import Storage
import SwiftData

/// The repositories of the app. Each store runs on a serial queue of its own (`StoreExecutor`), never on the main
/// thread; they are still made off it, as the stores' `ModelContext`s are made while the content import may be
/// holding the store.
/// The CloudKit services (social and the public catalog) are made here too: `CKContainer(identifier:)` talks to
/// `cloudd` synchronously, and on the first launch, while SwiftData sets up the Personal store's iCloud mirroring, that
/// held the main thread and froze the Splash.
struct AppStores: Sendable {
    let maps: PalateMapStore
    let questions: QuizQuestionStore
    let profiles: ProfileStore
    let catalog: CatalogStore
    /// Courses and lessons, on a Content store actor of their own. An actor runs one read at a time, and the Home
    /// ranks all 10,000 wines on `catalog` (`winesClosest`, over a second on a fast device) every time it reloads,
    /// which it does right after the tabs first open. A lesson opened then waited behind that ranking; on its own
    /// actor it reads alongside it. It never asks the public catalog.
    let courses: CatalogStore
    let reminders: ReminderStore
    let cellar: CellarStore
    let learning: LearningStore
    let friends: FriendsStore
    /// The Home's notifications the user opened (HOME-R04).
    let notifications: NotificationStore
    let social: any SocialService
    /// The phone's copy of the public catalog, and the readings sent to it (ARCHITECTURE §4.1, §4.3).
    let catalogSync: CatalogSync

    /// `-UVVADemoAccount` (Debug only): friends and requests in memory, so the Friends tab can be walked through in
    /// the simulator without a second iCloud account.
    private static func makeSocial() -> any SocialService {
        #if DEBUG
        if DemoMode.isOn { return DemoSocial() }
        #endif
        return CloudKitSocialService()
    }

    static func make(container: ModelContainer) async -> AppStores {
        await Task.detached(priority: .userInitiated) {
            let catalogCloud = CloudKitCatalogService()
            return AppStores(maps: PalateMapStore(modelContainer: container),
                      questions: QuizQuestionStore(modelContainer: container),
                      profiles: ProfileStore(modelContainer: container),
                      catalog: CatalogStore(modelContainer: container, cloud: catalogCloud),
                      courses: CatalogStore(modelContainer: container),
                      reminders: ReminderStore(modelContainer: container),
                      cellar: CellarStore(modelContainer: container),
                      learning: LearningStore(modelContainer: container),
                      friends: FriendsStore(modelContainer: container),
                      notifications: NotificationStore(modelContainer: container),
                      social: makeSocial(),
                      catalogSync: CatalogSync(cloud: catalogCloud, writer: CatalogWriter(modelContainer: container)))
        }.value
    }
}
