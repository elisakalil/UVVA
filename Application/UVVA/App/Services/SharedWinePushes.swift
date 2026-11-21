import CloudKit
import Core
import UIKit
import UserNotifications

/// FRI-R11c: the pushes of the wines friends send. Asks for notifications once the user has a friend, subscribes to
/// the wines sent to them on the public database, and hands the wine a tapped push names to the app.
@MainActor
final class SharedWinePushes: NSObject, UNUserNotificationCenterDelegate {
    static let shared = SharedWinePushes()

    /// Opens a wine sent, by its record. Until the app sets it, a tapped push waits in `pending`.
    var onOpen: ((String) -> Void)? {
        didSet {
            guard let onOpen, let pending else { return }
            self.pending = nil
            onOpen(pending)
        }
    }

    private var pending: String?

    /// Called at launch, before any push can be tapped.
    func start() {
        UNUserNotificationCenter.current().delegate = self
    }

    /// Asks for notifications (iOS asks only once), registers for pushes and subscribes to the wines sent to the user.
    func prepare(userID: String, sharing: any WineSharingService) async {
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return }
        UIApplication.shared.registerForRemoteNotifications()
        try? await sharing.subscribeToSharedWines(userID: userID)
    }

    /// A push of a wine sent: the record it names. Any other push is not this one's.
    nonisolated static func sharedWineID(_ userInfo: [AnyHashable: Any]) -> String? {
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) as? CKQueryNotification,
              notification.subscriptionID?.hasPrefix(SharedWinePush.subscriptionPrefix) == true else { return nil }
        return notification.recordID?.recordName
    }

    private func open(_ id: String) {
        if let onOpen { onOpen(id) } else { pending = id }
    }

    // MARK: UNUserNotificationCenterDelegate

    /// With the app open, the push still shows as a banner.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification)
        async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let id = Self.sharedWineID(response.notification.request.content.userInfo) else { return }
        await MainActor.run { open(id) }
    }
}

/// The app delegate, for the pushes alone.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        MainActor.assumeIsolated { SharedWinePushes.shared.start() }
        return true
    }
}
