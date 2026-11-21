import Core
import Foundation
import SwiftData

/// `NotificationsRepository` on the Personal store. CloudKit allows no unique attributes, so a notification read on
/// two devices may arrive twice; reading it as a set makes that harmless.
public actor NotificationStore: StoreActor, NotificationsRepository {
    public nonisolated let executor: StoreExecutor

    /// The Home lists 30 days of notifications (HOME-R04a); what was read long before that can go.
    static let keptFor: TimeInterval = 90 * 24 * 3600

    public init(modelContainer: ModelContainer) {
        executor = StoreExecutor(modelContainer, label: "app.uvva.store.notifications")
    }

    public func readNotifications() throws -> Set<String> {
        Set(try modelContext.fetch(FetchDescriptor<ReadNotificationEntity>()).map(\.notificationID))
    }

    public func markRead(_ id: String) throws {
        let all = try modelContext.fetch(FetchDescriptor<ReadNotificationEntity>())
        let cutoff = Date.now.addingTimeInterval(-Self.keptFor)
        for old in all where old.readAt < cutoff { modelContext.delete(old) }
        if !all.contains(where: { $0.notificationID == id }) {
            modelContext.insert(ReadNotificationEntity(notificationID: id, readAt: .now))
        }
        try modelContext.save()
    }
}
