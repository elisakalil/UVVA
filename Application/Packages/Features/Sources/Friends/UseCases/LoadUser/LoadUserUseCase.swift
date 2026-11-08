import Core
import Foundation

/// The profile and the map. Nil before the Quiz is done, which the tabs never show.
@MainActor
struct LoadUserUseCase: LoadUserUseCaseProtocol {
    let profiles: any ProfileRepository
    let maps: any PalateMapRepository

    func execute() async throws -> FriendsUser? {
        guard let profile = try await profiles.currentProfile(), let map = try await maps.currentMap() else { return nil }
        return FriendsUser(id: profile.id, firstName: profile.firstName, map: map, inviteLink: profile.inviteLink)
    }
}
