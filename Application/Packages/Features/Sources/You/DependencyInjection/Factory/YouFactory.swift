import Core
import Foundation

@MainActor
public struct YouFactory: YouFactoryProtocol {
    private let profiles: any ProfileRepository
    private let maps: any PalateMapRepository
    private let catalog: any CatalogRepository
    private let courses: any CourseCatalog
    private let learning: any LearningRepository
    private let social: any SocialService
    private let reminders: any ReminderRepository
    private let scheduler: any ReminderScheduling

    public init(profiles: any ProfileRepository, maps: any PalateMapRepository, catalog: any CatalogRepository,
                courses: any CourseCatalog, learning: any LearningRepository, social: any SocialService,
                reminders: any ReminderRepository, scheduler: any ReminderScheduling) {
        self.profiles = profiles
        self.maps = maps
        self.catalog = catalog
        self.courses = courses
        self.learning = learning
        self.social = social
        self.reminders = reminders
        self.scheduler = scheduler
    }

    public func makeViewModel(coordinator: any YouCoordinatorProtocol) -> YouViewModel {
        YouViewModel(
            loadYouUseCase: LoadYouUseCase(profiles: profiles, maps: maps, catalog: catalog, courses: courses,
                                          learning: learning, reminders: reminders),
            makeScreens: { owner in
                let readModel = { [weak owner] in owner?.contentModel ?? YouContentModel() }
                return (
                    ProgressViewModel(readModel: readModel, coordinator: coordinator),
                    MapViewModel(content: readModel(), coordinator: coordinator),
                    makeSettings(owner: owner, coordinator: coordinator)
                )
            }
        )
    }

    private func makeSettings(owner: YouViewModel, coordinator: any YouCoordinatorProtocol) -> SettingsViewModel {
        let saveProfile = SaveProfileUseCase(profiles: profiles, social: social)
        let readModel = { [weak owner] in owner?.contentModel ?? YouContentModel() }
        let onProfileSaved: (Profile) -> Void = { [weak owner] in owner?.profileSaved($0) }
        return SettingsViewModel(
            readModel: readModel, onProfileSaved: onProfileSaved, coordinator: coordinator,
            savePhotoUseCase: SavePhotoUseCase(saveProfile: saveProfile),
            setMapPublicUseCase: SetMapPublicUseCase(saveProfile: saveProfile),
            signOutUseCase: SignOutUseCase(scheduler: scheduler),
            deleteAccountUseCase: DeleteAccountUseCase(social: social, profiles: profiles, scheduler: scheduler),
            editName: EditNameViewModel(readModel: readModel, onProfileSaved: onProfileSaved,
                                         saveNameUseCase: SaveNameUseCase(saveProfile: saveProfile)),
            editPhone: EditPhoneViewModel(readModel: readModel, onProfileSaved: onProfileSaved,
                                           savePhoneUseCase: SavePhoneUseCase(saveProfile: saveProfile, social: social)),
            reminder: ReminderViewModel(readModel: readModel,
                                          onReminderSaved: { [weak owner] in owner?.reminderSaved($0) },
                                          saveReminderUseCase: SaveReminderUseCase(reminders: reminders, scheduler: scheduler)),
            certificates: CertificatesViewModel(readModel: readModel, coordinator: coordinator)
        )
    }
}
