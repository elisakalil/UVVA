import Core
import Foundation

@MainActor
struct SavePhotoUseCase: SavePhotoUseCaseProtocol {
    let saveProfile: any SaveProfileUseCaseProtocol

    /// `nil` removes the photo: the profile goes back to the figure over the vineyard (YOU-R14a).
    func execute(_ jpeg: Data?, profile: Profile) async throws -> Profile {
        var updated = profile
        updated.photo = jpeg
        try await saveProfile.execute(updated, map: nil, publish: false)
        return updated
    }
}
