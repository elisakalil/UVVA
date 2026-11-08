import Core
import Foundation

/// PLANO-FRIENDS §2: the requests in both directions make the friendship; the friends' public profiles give the
/// names and maps, kept on the device so the tab opens without network.
@MainActor
struct RefreshFriendsUseCase: RefreshFriendsUseCaseProtocol {
    let social: any SocialService
    let friends: any FriendsRepository

    func cached() async -> [Friend] {
        (try? await friends.friends()) ?? []
    }

    func execute(userID: String) async throws -> FriendsSnapshot {
        async let sent = social.friendRequests(from: userID)
        async let received = social.friendRequests(to: userID)
        let declined = try await friends.declinedRequests()
        let known = Set(try await friends.friends().map(\.id))
        let friendship = Friendship.resolve(user: userID, sent: try await sent, received: try await received,
                                            declined: declined, knownFriends: known)

        // A friend took their request back (D4): the user's own goes too, so it does not come back as a request.
        for request in friendship.lapsed {
            try? await social.deleteFriendRequest(from: request.from, to: request.to)
        }

        let profiles = try await social.profiles(ids: Array(friendship.friends.keys) + friendship.incoming.map(\.from))
        // FRI-R01: every friend has a map. A profile without one (gone, or the map made private, N5) is left out.
        let list = friendship.friends.compactMap { id, addedAt -> Friend? in
            guard let profile = profiles[id], let map = profile.map else { return nil }
            return Friend(id: id, name: profile.firstName, map: map, addedAt: addedAt)
        }
        try await friends.replaceFriends(list)

        let incoming = friendship.incoming.compactMap { request -> IncomingRequest? in
            guard let profile = profiles[request.from], let map = profile.map else { return nil }
            return IncomingRequest(id: request.from, name: profile.firstName, map: map, sentAt: request.createdAt)
        }
        return FriendsSnapshot(friends: list, incoming: incoming, requested: Set(friendship.outgoing.map(\.to)))
    }
}
