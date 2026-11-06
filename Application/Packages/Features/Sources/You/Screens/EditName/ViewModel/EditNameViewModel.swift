import Core
import Foundation
import Combine

@MainActor
public final class EditNameViewModel: EditNameViewModelProtocol {
    @Published public private(set) var uiModel = EditNameUIModel()
    private let onProfileSaved: (Profile) -> Void
    private let readModel: () -> YouContentModel
    private let saveNameUseCase: any SaveNameUseCaseProtocol

    init(readModel: @escaping () -> YouContentModel, onProfileSaved: @escaping (Profile) -> Void, saveNameUseCase: any SaveNameUseCaseProtocol) {
        self.readModel = readModel
        self.onProfileSaved = onProfileSaved
        self.saveNameUseCase = saveNameUseCase
    }

    public func prepare() { uiModel.name = readModel().profile?.firstName ?? ""; uiModel.notice = nil }

    public func updateName(_ name: String) { uiModel.name = name }

    public func saveName(_ name: String) async -> Bool {
        guard let profile = readModel().profile, !uiModel.isSaving else { return false }
        uiModel.isSaving = true
        uiModel.notice = nil
        defer { uiModel.isSaving = false }
        do {
            onProfileSaved(try await saveNameUseCase.execute(name, profile: profile, map: readModel().map))
            return true
        } catch is ProfileEditError {
            return false
        } catch {
            uiModel.notice = uiModel.yourChangesCouldNotBeText
            return false
        }
    }
}
