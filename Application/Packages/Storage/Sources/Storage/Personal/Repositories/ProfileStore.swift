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
}
