import Core
import Foundation

@MainActor
struct SaveNameUseCase: SaveNameUseCaseProtocol {
    let saveProfile: any SaveProfileUseCaseProtocol

    func execute(_ name: String, profile: Profile, map: PalateMap?) async throws -> Profile {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { throw ProfileEditError.invalidName }
        var updated = profile
        updated.firstName = trimmed
        try await saveProfile.execute(updated, map: map, publish: true)
        return updated
    }
}
