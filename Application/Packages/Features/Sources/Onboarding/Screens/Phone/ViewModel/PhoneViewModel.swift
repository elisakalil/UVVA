import Core
import Foundation
import Observation

@MainActor @Observable
final class PhoneViewModel {
    private(set) var country: PhoneCountry
    private(set) var phoneDigits = ""
    private(set) var isSaving = false
    private(set) var notice: String?

    private let draft: OnboardingDraft
    private let createAccountUseCase: any CreateAccountUseCaseProtocol
    private weak var coordinator: (any OnboardingCoordinatorProtocol)?

    init(draft: OnboardingDraft, country: PhoneCountry,
         createAccountUseCase: any CreateAccountUseCaseProtocol,
         coordinator: any OnboardingCoordinatorProtocol) {
        self.draft = draft
        self.country = country
        self.createAccountUseCase = createAccountUseCase
        self.coordinator = coordinator
    }

    func back() { coordinator?.back() }

    /// Room for a trunk prefix on top of the longest national number.
    private var maxDigits: Int { country.nationalLength.upperBound + (country.trunkPrefix?.count ?? 0) }

    var phoneE164: String? { PhoneNumber.e164(national: phoneDigits, country: country) }

    func press(_ digit: Character) {
        guard digit.isNumber, phoneDigits.count < maxDigits else { return }
        phoneDigits.append(digit)
    }

    func deleteDigit() {
        guard !phoneDigits.isEmpty else { return }
        phoneDigits.removeLast()
    }

    func select(_ country: PhoneCountry) {
        self.country = country
        if phoneDigits.count > maxDigits { phoneDigits = String(phoneDigits.prefix(maxDigits)) }
    }

    /// "Continue" (ONB-R07).
    func continueWithPhone() async {
        guard let phone = phoneE164 else { return }
        await startSession(phone: phone)
    }

    /// "Skip for now" (ONB-R35).
    func skipPhone() async {
        await startSession(phone: nil)
    }

    private func startSession(phone: String?) async {
        guard let identity = draft.identity, !isSaving else { return }
        isSaving = true
        notice = nil
        defer { isSaving = false }
        do {
            let profile = try await createAccountUseCase.execute(identity: identity, name: draft.name, phone: phone)
            coordinator?.accountCreated(profile)
        } catch {
            notice = String(localized: "Your account could not be saved. Try again.", bundle: .module)
        }
    }

    var phoneModel: PhoneUIModel {
        PhoneUIModel(country: country, dialCode: "+" + country.callingCode,
                     number: phoneDigits.isEmpty ? Self.example(for: country) : PhoneNumber.grouped(phoneDigits),
                     isEmpty: phoneDigits.isEmpty, canContinue: phoneE164 != nil, isSaving: isSaving)
    }

    /// ONB-R03: "912 345 678" for Portugal; zeros of the right length elsewhere.
    static func example(for country: PhoneCountry) -> String {
        country.region == "PT" ? "912 345 678"
            : PhoneNumber.grouped(String(repeating: "0", count: country.nationalLength.upperBound))
    }

}
