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
    private let now: () -> Date
    private let calendar: Calendar

    public init(profiles: any ProfileRepository, maps: any PalateMapRepository, catalog: any CatalogRepository,
                courses: any CourseCatalog, learning: any LearningRepository, social: any SocialService,
                reminders: any ReminderRepository, scheduler: any ReminderScheduling,
                now: @escaping () -> Date = Date.init, calendar: Calendar = .current) {
        self.profiles = profiles
        self.maps = maps
        self.catalog = catalog
        self.courses = courses
        self.learning = learning
        self.social = social
        self.reminders = reminders
        self.scheduler = scheduler
        self.now = now
        self.calendar = calendar
    }

    public func makeViewModel(coordinator: any YouCoordinatorProtocol) -> YouViewModel {
        let state = YouState()
        return YouViewModel(
            state: state,
            loadYouUseCase: LoadYouUseCase(profiles: profiles, maps: maps, catalog: catalog, courses: courses,
                                          learning: learning, reminders: reminders),
            progress: ProgressViewModel(state: state, coordinator: coordinator),
            map: MapViewModel(state: state, coordinator: coordinator, now: now, calendar: calendar),
            settings: makeSettings(state: state, coordinator: coordinator)
        )
    }

    private func makeSettings(state: YouState, coordinator: any YouCoordinatorProtocol) -> SettingsViewModel {
        let saveProfile = SaveProfileUseCase(profiles: profiles, social: social)
        return SettingsViewModel(
            state: state, coordinator: coordinator,
            savePhotoUseCase: SavePhotoUseCase(saveProfile: saveProfile),
            setMapPublicUseCase: SetMapPublicUseCase(saveProfile: saveProfile),
            signOutUseCase: SignOutUseCase(scheduler: scheduler),
            deleteAccountUseCase: DeleteAccountUseCase(social: social, profiles: profiles, scheduler: scheduler),
            editName: EditNameViewModel(state: state, saveNameUseCase: SaveNameUseCase(saveProfile: saveProfile)),
            editPhone: EditPhoneViewModel(state: state,
                                         savePhoneUseCase: SavePhoneUseCase(saveProfile: saveProfile, social: social)),
            reminder: ReminderViewModel(state: state,
                                        saveReminderUseCase: SaveReminderUseCase(reminders: reminders, scheduler: scheduler)),
            certificates: CertificatesViewModel(state: state, coordinator: coordinator)
        )
    }
}
