import Core
import Foundation

@MainActor
protocol DeleteAccountUseCaseProtocol {
    func execute(_ profile: Profile) async throws
}
