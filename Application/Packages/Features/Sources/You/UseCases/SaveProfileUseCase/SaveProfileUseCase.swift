import Core
import Foundation

@MainActor
struct SaveProfileUseCase: SaveProfileUseCaseProtocol {
    let profiles: any ProfileRepository
    let social: any SocialService

    func execute(_ profile: Profile, map: PalateMap?, publish: Bool) async throws {
        try await profiles.save(profile)
        guard publish else { return }
        let social = social
        Task.detached {
            try? await social.publish(PublicProfile(id: profile.id, firstName: profile.firstName,
                                                    map: profile.mapIsPublic ? map : nil, hasMap: map != nil))
        }
    }
}
