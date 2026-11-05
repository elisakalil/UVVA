import Core
import Foundation
import Observation

@MainActor @Observable
final class EditPhoneViewModel {
    var country = PhoneCountries.defaultCountry()
    var national = ""
    private(set) var isSaving = false
    private(set) var notice: String?
    private let state: YouState
    private let savePhoneUseCase: any SavePhoneUseCaseProtocol

    init(state: YouState, savePhoneUseCase: any SavePhoneUseCaseProtocol) {
        self.state = state
        self.savePhoneUseCase = savePhoneUseCase
    }

    var digits: String { national.filter(\.isNumber) }
    var isValid: Bool { digits.isEmpty || PhoneNumber.e164(national: digits, country: country) != nil }

    func prepare() {
        let parts = PhonePresentation.parts(state.content.profile?.phone)
        country = parts.country
        national = parts.national
        notice = nil
    }

    func savePhone(national: String, country: PhoneCountry) async -> Bool {
        guard let profile = state.content.profile, !isSaving else { return false }
        isSaving = true
        notice = nil
        defer { isSaving = false }
        do {
            state.content.profile = try await savePhoneUseCase.execute(national: national, country: country, profile: profile)
            return true
        } catch is ProfileEditError {
            return false
        } catch {
            notice = String(localized: "Your changes could not be saved. Try again.", bundle: .module)
            return false
        }
    }
}
