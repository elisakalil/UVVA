import Core
import Foundation

@MainActor
protocol SignInUseCaseProtocol {
    func execute() async throws -> AuthIdentity?
}
