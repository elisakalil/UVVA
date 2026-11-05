import Foundation
import Observation

@MainActor @Observable
final class EditNameViewModel {
    var name = ""
    private(set) var isSaving = false
    private(set) var notice: String?
    private let state: YouState
    private let saveNameUseCase: any SaveNameUseCaseProtocol

    init(state: YouState, saveNameUseCase: any SaveNameUseCaseProtocol) {
        self.state = state
        self.saveNameUseCase = saveNameUseCase
    }

    var isValid: Bool { name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 }
    func prepare() { name = state.content.profile?.firstName ?? ""; notice = nil }

    func saveName(_ name: String) async -> Bool {
        guard let profile = state.content.profile, !isSaving else { return false }
        isSaving = true
        notice = nil
        defer { isSaving = false }
        do {
            state.content.profile = try await saveNameUseCase.execute(name, profile: profile, map: state.content.map)
            return true
        } catch is ProfileEditError {
            return false
        } catch {
            notice = String(localized: "Your changes could not be saved. Try again.", bundle: .module)
            return false
        }
    }
}
