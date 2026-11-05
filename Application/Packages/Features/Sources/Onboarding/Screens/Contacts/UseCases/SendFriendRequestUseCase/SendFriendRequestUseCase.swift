import Core
import Foundation

@MainActor
struct SendFriendRequestUseCase: SendFriendRequestUseCaseProtocol {
    let social: any SocialService

    func execute(from userID: String, to friendID: String) async throws {
        try await social.sendFriendRequest(from: userID, to: friendID)
    }
}
