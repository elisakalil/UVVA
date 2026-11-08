import Core
import Foundation

/// `×` (FRI-R09): the suggestion goes, with no request, and is not suggested again (D4).
@MainActor
struct DismissSuggestionUseCase: DismissSuggestionUseCaseProtocol {
    let friends: any FriendsRepository

    func execute(_ userID: String) async throws {
        try await friends.dismissSuggestion(userID)
    }
}
