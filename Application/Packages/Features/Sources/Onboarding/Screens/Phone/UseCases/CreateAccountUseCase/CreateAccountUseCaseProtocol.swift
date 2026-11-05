import Core
import Foundation

@MainActor
protocol CreateAccountUseCaseProtocol {
    func execute(identity: AuthIdentity, name: String, phone: String?) async throws -> Profile
}
