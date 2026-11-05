import Foundation
import Combine

@MainActor
public final class EditNameViewModel: EditNameViewModelProtocol {
    @Published public private(set) var uiModel = EditNameUIModel()
    private let state: YouState
    private let saveNameUseCase: any SaveNameUseCaseProtocol

    init(state: YouState, saveNameUseCase: any SaveNameUseCaseProtocol) {
        self.state = state
        self.saveNameUseCase = saveNameUseCase
    }

    public func prepare() { uiModel.name = state.content.profile?.firstName ?? ""; uiModel.notice = nil }

    public func updateName(_ name: String) { uiModel.name = name }

    public func saveName(_ name: String) async -> Bool {
        guard let profile = state.content.profile, !uiModel.isSaving else { return false }
        uiModel.isSaving = true
        uiModel.notice = nil
        defer { uiModel.isSaving = false }
        do {
            state.content.profile = try await saveNameUseCase.execute(name, profile: profile, map: state.content.map)
            return true
        } catch is ProfileEditError {
            return false
        } catch {
            uiModel.notice = uiModel.yourChangesCouldNotBeText
            return false
        }
    }
}
