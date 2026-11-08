import Core
import Foundation

/// Tapping "Requested" takes the request back (D11).
@MainActor
struct CancelRequestUseCase: CancelRequestUseCaseProtocol {
    let social: any SocialService

    func execute(from userID: String, to friendID: String) async throws {
        try await social.deleteFriendRequest(from: userID, to: friendID)
    }
}
