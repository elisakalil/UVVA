import Core
import Foundation

@MainActor
struct SavePhoneUseCase: SavePhoneUseCaseProtocol {
    let saveProfile: any SaveProfileUseCaseProtocol
    let social: any SocialService

    func execute(national: String, country: PhoneCountry, profile: Profile) async throws -> Profile {
        let phone = try normalizedPhone(national, country: country)
        var updated = profile
        updated.phone = phone
        try await saveProfile.execute(updated, map: nil, publish: false)
        if profile.phone != phone { updateContactKey(from: profile.phone, to: phone, userID: profile.id) }
        return updated
    }

    private func normalizedPhone(_ national: String, country: PhoneCountry) throws -> String? {
        guard !national.isEmpty else { return nil }
        guard let phone = PhoneNumber.e164(national: national, country: country) else {
            throw ProfileEditError.invalidPhone
        }
        return phone
    }

    private func updateContactKey(from old: String?, to phone: String?, userID: String) {
        let social = social
        Task.detached {
            if let old { try? await social.removeContactKey(phone: old) }
            if let phone { _ = try? await social.publishContactKey(phone: phone, userID: userID) }
        }
    }
}
