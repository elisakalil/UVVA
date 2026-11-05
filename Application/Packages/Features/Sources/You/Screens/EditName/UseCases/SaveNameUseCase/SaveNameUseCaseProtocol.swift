import Core
import Foundation

@MainActor
protocol SaveNameUseCaseProtocol {
    func execute(_ name: String, profile: Profile, map: PalateMap?) async throws -> Profile
}
