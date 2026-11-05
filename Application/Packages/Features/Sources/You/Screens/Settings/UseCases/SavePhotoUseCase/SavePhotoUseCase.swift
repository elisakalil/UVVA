import Core
import Foundation

@MainActor
struct SavePhotoUseCase: SavePhotoUseCaseProtocol {
    let saveProfile: any SaveProfileUseCaseProtocol

    func execute(_ jpeg: Data, profile: Profile) async throws -> Profile {
        var updated = profile
        updated.photo = jpeg
        try await saveProfile.execute(updated, map: nil, publish: false)
        return updated
    }
}
