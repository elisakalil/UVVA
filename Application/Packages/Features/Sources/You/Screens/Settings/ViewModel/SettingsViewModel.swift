import Core
import Foundation
import Combine

@MainActor
public final class SettingsViewModel: SettingsViewModelProtocol {
    @Published public private(set) var uiModel: SettingsUIModel
    public let editName: EditNameViewModel
    public let editPhone: EditPhoneViewModel
    public let reminder: ReminderViewModel
    public let certificates: CertificatesViewModel

    private let onProfileSaved: (Profile) -> Void
    private let readModel: () -> YouContentModel
    private let coordinator: any YouCoordinatorProtocol
    private let savePhotoUseCase: any SavePhotoUseCaseProtocol
    private let setMapPublicUseCase: any SetMapPublicUseCaseProtocol
    private let signOutUseCase: any SignOutUseCaseProtocol
    private let deleteAccountUseCase: any DeleteAccountUseCaseProtocol

    init(readModel: @escaping () -> YouContentModel, onProfileSaved: @escaping (Profile) -> Void, coordinator: any YouCoordinatorProtocol,
         savePhotoUseCase: any SavePhotoUseCaseProtocol, setMapPublicUseCase: any SetMapPublicUseCaseProtocol,
         signOutUseCase: any SignOutUseCaseProtocol, deleteAccountUseCase: any DeleteAccountUseCaseProtocol,
         editName: EditNameViewModel, editPhone: EditPhoneViewModel, reminder: ReminderViewModel,
         certificates: CertificatesViewModel) {
        self.readModel = readModel
        self.onProfileSaved = onProfileSaved
        self.coordinator = coordinator
        self.savePhotoUseCase = savePhotoUseCase
        self.setMapPublicUseCase = setMapPublicUseCase
        self.signOutUseCase = signOutUseCase
        self.deleteAccountUseCase = deleteAccountUseCase
        self.editName = editName
        self.editPhone = editPhone
        self.reminder = reminder
        self.certificates = certificates
        uiModel = SettingsPresentationBuilder().build(from: readModel())

    }


    func present(_ model: YouContentModel) {
        var presentation = SettingsPresentationBuilder().build(from: model)
        presentation.notice = uiModel.notice
        presentation.isWorking = uiModel.isWorking
        uiModel = presentation
        certificates.present(model)
    }

    public func savePhoto(_ jpeg: Data) async {
        guard let profile = readModel().profile else { return }
        do {
            onProfileSaved(try await savePhotoUseCase.execute(jpeg, profile: profile))
        } catch {
            uiModel.notice = uiModel.yourChangesCouldNotBeText
        }
    }

    public func setMapPublic(_ isPublic: Bool) async {
        guard let profile = readModel().profile else { return }
        do {
            onProfileSaved(try await setMapPublicUseCase.execute(isPublic, profile: profile, map: readModel().map))
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
        guard let profile = readModel().profile, !uiModel.isWorking else { return }
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
