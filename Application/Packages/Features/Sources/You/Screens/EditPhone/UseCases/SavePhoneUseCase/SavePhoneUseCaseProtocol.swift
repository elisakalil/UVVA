import Core
import Foundation

@MainActor
protocol SavePhoneUseCaseProtocol {
    func execute(national: String, country: PhoneCountry, profile: Profile) async throws -> Profile
}
