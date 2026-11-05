import Core
import Foundation
import Combine

@MainActor
public final class EditPhoneViewModel: EditPhoneViewModelProtocol {
    @Published public private(set) var uiModel = EditPhoneUIModel()
    private let state: YouState
    private let savePhoneUseCase: any SavePhoneUseCaseProtocol

    init(state: YouState, savePhoneUseCase: any SavePhoneUseCaseProtocol) {
        self.state = state
        self.savePhoneUseCase = savePhoneUseCase
    }

    public func updateNational(_ value: String) { uiModel.national = value }
    public func selectCountry(_ country: PhoneCountry) { uiModel.country = country }

    public func prepare() {
        let parts = PhonePresentation.parts(state.content.profile?.phone)
        uiModel.country = parts.country
        uiModel.national = parts.national
        uiModel.notice = nil
    }

    public func savePhone(national: String, country: PhoneCountry) async -> Bool {
        guard let profile = state.content.profile, !uiModel.isSaving else { return false }
        uiModel.isSaving = true
        uiModel.notice = nil
        defer { uiModel.isSaving = false }
        do {
            state.content.profile = try await savePhoneUseCase.execute(national: national, country: country, profile: profile)
            return true
        } catch is ProfileEditError {
            return false
        } catch {
            uiModel.notice = uiModel.yourChangesCouldNotBeText
            return false
        }
    }
}
