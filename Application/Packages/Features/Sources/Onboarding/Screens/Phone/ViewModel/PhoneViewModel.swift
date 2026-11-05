import Core
import Foundation
import Combine

@MainActor
final class PhoneViewModel: PhoneViewModelProtocol {
    @Published private(set) var uiModel: PhoneUIModel
    private var phoneDigits = ""

    private let draft: OnboardingDraft
    private let createAccountUseCase: any CreateAccountUseCaseProtocol
    private weak var coordinator: (any OnboardingCoordinatorProtocol)?

    init(draft: OnboardingDraft, country: PhoneCountry,
         createAccountUseCase: any CreateAccountUseCaseProtocol,
         coordinator: any OnboardingCoordinatorProtocol) {
        self.draft = draft
        self.uiModel = PhoneUIModel(country: country, dialCode: "+" + country.callingCode,
                                    number: Self.example(for: country), isEmpty: true,
                                    canContinue: false, isSaving: false)
        self.createAccountUseCase = createAccountUseCase
        self.coordinator = coordinator
    }

    func back() { coordinator?.back() }

    /// Room for a trunk prefix on top of the longest national number.
    private var maxDigits: Int { uiModel.country.nationalLength.upperBound + (uiModel.country.trunkPrefix?.count ?? 0) }

    var phoneE164: String? { PhoneNumber.e164(national: phoneDigits, country: uiModel.country) }

    func press(_ digit: Character) {
        guard digit.isNumber, phoneDigits.count < maxDigits else { return }
        phoneDigits.append(digit)
        refresh()
    }

    func deleteDigit() {
        guard !phoneDigits.isEmpty else { return }
        phoneDigits.removeLast()
        refresh()
    }

    func select(_ country: PhoneCountry) {
        uiModel.country = country
        if phoneDigits.count > maxDigits { phoneDigits = String(phoneDigits.prefix(maxDigits)) }
        refresh()
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
        guard let identity = draft.identity, !uiModel.isSaving else { return }
        uiModel.isSaving = true
        uiModel.notice = nil
        defer { uiModel.isSaving = false }
        do {
            let profile = try await createAccountUseCase.execute(identity: identity, name: draft.name, phone: phone)
            coordinator?.accountCreated(profile)
        } catch {
            uiModel.notice = uiModel.saveError
        }
    }

    private func refresh() {
        uiModel.dialCode = "+" + uiModel.country.callingCode
        uiModel.number = phoneDigits.isEmpty ? Self.example(for: uiModel.country) : PhoneNumber.grouped(phoneDigits)
        uiModel.isEmpty = phoneDigits.isEmpty
        uiModel.canContinue = phoneE164 != nil
    }

    /// ONB-R03: "912 345 678" for Portugal; zeros of the right length elsewhere.
    static func example(for country: PhoneCountry) -> String {
        country.region == "PT" ? "912 345 678"
            : PhoneNumber.grouped(String(repeating: "0", count: country.nationalLength.upperBound))
    }

}
