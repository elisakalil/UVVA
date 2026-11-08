import Core
import Foundation

/// "Add" (FRI-R08), and "Accept", which is the same request sent back (FRI-R08a, PLANO-FRIENDS §2).
@MainActor
struct SendFriendRequestUseCase: SendFriendRequestUseCaseProtocol {
    let social: any SocialService

    func execute(from userID: String, to friendID: String) async throws {
        try await social.sendFriendRequest(from: userID, to: friendID)
    }
}
