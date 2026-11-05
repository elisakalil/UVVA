import Core
import Foundation

@MainActor
struct SignInUseCase: SignInUseCaseProtocol {
    let auth: any Authenticating

    func execute() async throws -> AuthIdentity? {
        try await auth.signIn()
    }
}
