import Core
import Foundation

/// "Decline" (FRI-R08a): kept on the user's account only, so nothing reaches the sender.
@MainActor
struct DeclineRequestUseCase: DeclineRequestUseCaseProtocol {
    let friends: any FriendsRepository

    func execute(_ senderID: String) async throws {
        try await friends.decline(senderID)
    }
}
