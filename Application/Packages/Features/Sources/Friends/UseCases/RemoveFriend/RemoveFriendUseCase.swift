import Core
import Foundation

/// D4: removing a friend takes the user's request back, without telling them. Their request stays until their
/// next refresh, so it is kept as declined here, and never shows as a request to the user.
@MainActor
struct RemoveFriendUseCase: RemoveFriendUseCaseProtocol {
    let social: any SocialService
    let friends: any FriendsRepository

    func execute(userID: String, friendID: String) async throws {
        try await social.deleteFriendRequest(from: userID, to: friendID)
        try await friends.decline(friendID)
        let remaining = try await friends.friends().filter { $0.id != friendID }
        try await friends.replaceFriends(remaining)
        if try await friends.lastTable()?.contains(friendID) == true { try await friends.saveLastTable([]) }
    }
}
