import Core
import Foundation

@MainActor
protocol SaveProfileUseCaseProtocol {
    func execute(_ profile: Profile, map: PalateMap?, publish: Bool) async throws
}
