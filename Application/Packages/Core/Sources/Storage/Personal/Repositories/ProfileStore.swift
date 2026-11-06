import Core
import Foundation
import SwiftData

/// `ProfileRepository` on the Personal store.
@ModelActor
public actor ProfileStore: ProfileRepository {
    /// The oldest profile, in case two devices each made one before syncing.
    public func currentProfile() throws -> Profile? {
        var descriptor = FetchDescriptor<ProfileEntity>(sortBy: [SortDescriptor(\.createdAt)])
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.profile
    }

    /// SwiftData brings the Personal store down from iCloud on its own; on a new device that takes a moment,
    /// so this looks again every half second until `timeout`.
    public func profile(authUserID: String, waitingUpTo timeout: Duration) async throws -> Profile? {
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while true {
            let descriptor = FetchDescriptor<ProfileEntity>(predicate: #Predicate { $0.authUserID == authUserID },
                                                            sortBy: [SortDescriptor(\.createdAt)])
            if let found = try modelContext.fetch(descriptor).first { return found.profile }
            guard ContinuousClock.now < deadline else { return nil }
            try await Task.sleep(for: .milliseconds(500))
        }
    }

    public func save(_ profile: Profile) throws {
        let existing = try modelContext.fetch(FetchDescriptor<ProfileEntity>()).first { $0.id == profile.id }
        if let existing {
            existing.update(from: profile)
        } else {
            modelContext.insert(ProfileEntity(profile, createdAt: .now))
        }
        try modelContext.save()
    }

    public func markTourSeen(_ tour: String) throws {
        guard let entity = try modelContext.fetch(FetchDescriptor<ProfileEntity>(sortBy: [SortDescriptor(\.createdAt)])).first,
              !entity.seenTours.contains(tour) else { return }
        entity.seenTours.append(tour)
        try modelContext.save()
    }

    /// Deleting the records here also deletes them from the private iCloud database, through SwiftData's sync.
    public func deleteAccount() throws {
        for profile in try modelContext.fetch(FetchDescriptor<ProfileEntity>()) { modelContext.delete(profile) }
        for map in try modelContext.fetch(FetchDescriptor<PalateMapEntity>()) { modelContext.delete(map) }
        for reminder in try modelContext.fetch(FetchDescriptor<ReminderEntity>()) { modelContext.delete(reminder) }
        for entry in try modelContext.fetch(FetchDescriptor<CellarEntryEntity>()) { modelContext.delete(entry) }
        for lesson in try modelContext.fetch(FetchDescriptor<LessonProgressEntity>()) { modelContext.delete(lesson) }
        for module in try modelContext.fetch(FetchDescriptor<ModuleProgressEntity>()) { modelContext.delete(module) }
        for certificate in try modelContext.fetch(FetchDescriptor<CertificateEntity>()) { modelContext.delete(certificate) }
        try modelContext.save()
    }
}
