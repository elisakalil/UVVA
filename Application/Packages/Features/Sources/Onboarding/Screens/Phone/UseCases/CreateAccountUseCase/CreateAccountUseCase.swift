import Core
import Foundation

@MainActor
struct CreateAccountUseCase: CreateAccountUseCaseProtocol {
    let profiles: any ProfileRepository
    let social: any SocialService

    func execute(identity: AuthIdentity, name: String, phone: String?) async throws -> Profile {
        let profile = Profile(id: UUID().uuidString.lowercased(), authProvider: identity.provider,
                              authUserID: identity.userID, firstName: name, phone: phone)
        try await profiles.save(profile)
        publishWhenPossible(profile)
        return profile
    }

    /// Public records are best effort and must not delay or prevent local account creation.
    private func publishWhenPossible(_ profile: Profile) {
        let social = social
        Task.detached {
            if let phone = profile.phone {
                _ = try? await social.publishContactKey(phone: phone, userID: profile.id)
            }
            try? await social.publish(PublicProfile(id: profile.id, firstName: profile.firstName,
                                                    map: nil, hasMap: false))
        }
    }
}
