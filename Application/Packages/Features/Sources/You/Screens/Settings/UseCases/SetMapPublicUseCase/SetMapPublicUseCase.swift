import Core
import Foundation

@MainActor
struct SetMapPublicUseCase: SetMapPublicUseCaseProtocol {
    let saveProfile: any SaveProfileUseCaseProtocol

    func execute(_ isPublic: Bool, profile: Profile, map: PalateMap?) async throws -> Profile {
        var updated = profile
        updated.mapIsPublic = isPublic
        try await saveProfile.execute(updated, map: map, publish: true)
        return updated
    }
}
