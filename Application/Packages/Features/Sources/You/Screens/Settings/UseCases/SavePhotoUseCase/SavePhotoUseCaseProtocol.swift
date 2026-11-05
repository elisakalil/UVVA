import Core
import Foundation

@MainActor
protocol SavePhotoUseCaseProtocol {
    func execute(_ jpeg: Data, profile: Profile) async throws -> Profile
}
