import Core
import Foundation
import Combine

@MainActor
public final class SettingsViewModel: SettingsViewModelProtocol {
    @Published public private(set) var uiModel: SettingsUIModel
    private var subscription: AnyCancellable?
    public let editName: EditNameViewModel
    public let editPhone: EditPhoneViewModel
    public let reminder: ReminderViewModel
    public let certificates: CertificatesViewModel

    private let state: YouState
    private let coordinator: any YouCoordinatorProtocol
    private let savePhotoUseCase: any SavePhotoUseCaseProtocol
    private let setMapPublicUseCase: any SetMapPublicUseCaseProtocol
    private let signOutUseCase: any SignOutUseCaseProtocol
    private let deleteAccountUseCase: any DeleteAccountUseCaseProtocol

    init(state: YouState, coordinator: any YouCoordinatorProtocol,
         savePhotoUseCase: any SavePhotoUseCaseProtocol, setMapPublicUseCase: any SetMapPublicUseCaseProtocol,
         signOutUseCase: any SignOutUseCaseProtocol, deleteAccountUseCase: any DeleteAccountUseCaseProtocol,
         editName: EditNameViewModel, editPhone: EditPhoneViewModel, reminder: ReminderViewModel,
         certificates: CertificatesViewModel) {
        self.state = state
        self.coordinator = coordinator
        self.savePhotoUseCase = savePhotoUseCase
        self.setMapPublicUseCase = setMapPublicUseCase
        self.signOutUseCase = signOutUseCase
        self.deleteAccountUseCase = deleteAccountUseCase
        self.editName = editName
        self.editPhone = editPhone
        self.reminder = reminder
        self.certificates = certificates
        uiModel = SettingsPresentationBuilder().build(from: state.content)
        subscription = state.$content.sink { [weak self] content in
            guard let self else { return }
            var model = SettingsPresentationBuilder().build(from: content)
            model.notice = uiModel.notice
            model.isWorking = uiModel.isWorking
            uiModel = model
        }
    }


    public func savePhoto(_ jpeg: Data) async {
        guard let profile = state.content.profile else { return }
        do {
            state.content.profile = try await savePhotoUseCase.execute(jpeg, profile: profile)
        } catch {
            uiModel.notice = uiModel.yourChangesCouldNotBeText
        }
    }

    public func setMapPublic(_ isPublic: Bool) async {
        guard let profile = state.content.profile else { return }
        do {
            state.content.profile = try await setMapPublicUseCase.execute(isPublic, profile: profile, map: state.content.map)
        } catch {
            uiModel.notice = uiModel.yourChangesCouldNotBeText
        }
    }

    public func signOut() async {
        guard !uiModel.isWorking else { return }
        uiModel.isWorking = true
        defer { uiModel.isWorking = false }
        await signOutUseCase.execute()
        coordinator.signOut()
    }

    public func deleteAccount() async {
        guard let profile = state.content.profile, !uiModel.isWorking else { return }
        uiModel.isWorking = true
        uiModel.notice = nil
        defer { uiModel.isWorking = false }
        do {
            try await deleteAccountUseCase.execute(profile)
            coordinator.accountDeleted()
        } catch {
            uiModel.notice = uiModel.yourAccountCouldNotBeText
        }
    }
}
