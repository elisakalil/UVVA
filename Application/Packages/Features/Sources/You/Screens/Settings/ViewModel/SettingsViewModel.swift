import Core
import Foundation
import Observation

@MainActor @Observable
final class SettingsViewModel {
    private(set) var notice: String?
    private(set) var isWorking = false
    let editName: EditNameViewModel
    let editPhone: EditPhoneViewModel
    let reminder: ReminderViewModel
    let certificates: CertificatesViewModel

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
    }

    var model: SettingsUIModel { SettingsPresentationBuilder().build(from: state.content) }

    func savePhoto(_ jpeg: Data) async {
        guard let profile = state.content.profile else { return }
        do {
            state.content.profile = try await savePhotoUseCase.execute(jpeg, profile: profile)
        } catch {
            notice = String(localized: "Your changes could not be saved. Try again.", bundle: .module)
        }
    }

    func setMapPublic(_ isPublic: Bool) async {
        guard let profile = state.content.profile else { return }
        do {
            state.content.profile = try await setMapPublicUseCase.execute(isPublic, profile: profile, map: state.content.map)
        } catch {
            notice = String(localized: "Your changes could not be saved. Try again.", bundle: .module)
        }
    }

    func signOut() async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        await signOutUseCase.execute()
        coordinator.signOut()
    }

    func deleteAccount() async {
        guard let profile = state.content.profile, !isWorking else { return }
        isWorking = true
        notice = nil
        defer { isWorking = false }
        do {
            try await deleteAccountUseCase.execute(profile)
            coordinator.accountDeleted()
        } catch {
            notice = String(localized: "Your account could not be deleted. Check your connection and try again.", bundle: .module)
        }
    }
}
