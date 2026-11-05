import Core
import Foundation

@MainActor
public struct OnboardingFactory: OnboardingFactoryProtocol {
    private let auth: any Authenticating
    private let profiles: any ProfileRepository
    private let maps: any PalateMapRepository
    private let social: any SocialService
    private let cloud: any CloudAccountStatus
    private let contacts: any ContactsProviding
    private let homeCountry: PhoneCountry
    private let lookUpTimeout: Duration

    public init(auth: any Authenticating, profiles: any ProfileRepository, maps: any PalateMapRepository,
                social: any SocialService, cloud: any CloudAccountStatus, contacts: any ContactsProviding,
                homeCountry: PhoneCountry = PhoneCountries.defaultCountry(), lookUpTimeout: Duration = .seconds(4)) {
        self.auth = auth
        self.profiles = profiles
        self.maps = maps
        self.social = social
        self.cloud = cloud
        self.contacts = contacts
        self.homeCountry = homeCountry
        self.lookUpTimeout = lookUpTimeout
    }

    public func makeModule(onFinish: @escaping (OnboardingResult) -> Void) -> OnboardingModule {
        let draft = OnboardingDraft()
        let coordinator = OnboardingCoordinator(draft: draft, onFinish: onFinish)
        return OnboardingModule(
            draft: draft,
            coordinator: coordinator,
            welcome: makeWelcome(coordinator),
            name: NameViewModel(draft: draft, coordinator: coordinator),
            phone: PhoneViewModel(draft: draft, country: homeCountry,
                                  createAccountUseCase: CreateAccountUseCase(profiles: profiles, social: social),
                                  coordinator: coordinator),
            findFriends: FindFriendsViewModel(requestAccessUseCase: RequestContactsAccessUseCase(contacts: contacts),
                                              coordinator: coordinator),
            contacts: makeContacts(draft, coordinator)
        )
    }

    private func makeWelcome(_ coordinator: OnboardingCoordinator) -> WelcomeViewModel {
        WelcomeViewModel(cloud: cloud, signInUseCase: SignInUseCase(auth: auth),
                         findAccountUseCase: FindExistingAccountUseCase(profiles: profiles, maps: maps,
                                                                      timeout: lookUpTimeout),
                         coordinator: coordinator)
    }

    private func makeContacts(_ draft: OnboardingDraft, _ coordinator: OnboardingCoordinator) -> ContactsViewModel {
        ContactsViewModel(draft: draft,
                          findContactsUseCase: FindContactsOnUVVAUseCase(contacts: contacts, social: social,
                                                                        homeCountry: homeCountry),
                          sendRequestUseCase: SendFriendRequestUseCase(social: social), coordinator: coordinator)
    }
}
