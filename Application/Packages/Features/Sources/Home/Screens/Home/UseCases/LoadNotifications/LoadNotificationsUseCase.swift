import Core
import Foundation
import OSLog

/// HOME-R04a: reads what the notifications need beyond the Home's own data. The requests are worked out as the
/// Friends tab does (PLANO-FRIENDS §2), so a request shows here exactly when it shows there.
@MainActor
struct LoadNotificationsUseCase: LoadNotificationsUseCaseProtocol {
    let notifications: (any NotificationsRepository)?
    let profiles: any ProfileRepository
    let friends: any FriendsRepository
    let social: (any SocialService)?
    let sharing: (any WineSharingService)?
    private let logger = Logger(subsystem: "app.uvva", category: "home")

    init(notifications: (any NotificationsRepository)?, profiles: any ProfileRepository,
         friends: any FriendsRepository, social: (any SocialService)?, sharing: (any WineSharingService)?) {
        self.notifications = notifications
        self.profiles = profiles
        self.friends = friends
        self.social = social
        self.sharing = sharing
    }

    func sources() async -> HomeNotificationSources {
        let read = (try? await notifications?.readNotifications()) ?? []
        guard let userID = try? await profiles.currentProfile()?.id else {
            return HomeNotificationSources(read: read)
        }
        async let incoming = self.requests(userID: userID)
        async let received = self.wines(userID: userID)
        return await HomeNotificationSources(requests: incoming, wines: received, read: read)
    }

    func markRead(_ id: String) async {
        do {
            try await notifications?.markRead(id)
        } catch {
            logger.error("A notification was not kept as read: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func requests(userID: String) async -> [HomeNotificationSources.Request] {
        guard let social else { return [] }
        do {
            async let sent = social.friendRequests(from: userID)
            async let received = social.friendRequests(to: userID)
            let declined = (try? await friends.declinedRequests()) ?? []
            let known = Set(((try? await friends.friends()) ?? []).map(\.id))
            let incoming = Friendship.resolve(user: userID, sent: try await sent, received: try await received,
                                              declined: declined, knownFriends: known).incoming
            guard !incoming.isEmpty else { return [] }
            let profiles = try await social.profiles(ids: incoming.map(\.from))
            // FRI-R01: as in the Friends tab, a request from a profile without a map is not shown.
            return incoming.compactMap { request in
                guard let profile = profiles[request.from], profile.map != nil else { return nil }
                return .init(userID: request.from, name: profile.firstName, sentAt: request.createdAt)
            }
        } catch {
            logger.info("Friend requests wait: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    private func wines(userID: String) async -> [SharedWineRecord] {
        guard let sharing else { return [] }
        do {
            return try await sharing.sharedWines(to: userID)
        } catch {
            logger.info("Sent wines wait: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }
}
