import Core
import Foundation

@MainActor
protocol SetMapPublicUseCaseProtocol {
    func execute(_ isPublic: Bool, profile: Profile, map: PalateMap?) async throws -> Profile
}
