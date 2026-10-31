import Core
import Observation
import Onboarding
import OSLog
import Quizz
import Storage
import SwiftData

/// Decides which top-level screen shows and builds the features with their services.
/// Features never open each other: they report back here (APP-R06).
@MainActor @Observable
final class AppCoordinator {
    private(set) var route: AppRoute = .launching
    /// The feature on screen, made once when its route opens.
    private(set) var onboarding: OnboardingViewModel?
    private(set) var quiz: QuizViewModel?
    private(set) var profile: Profile?

    private let maps: PalateMapStore
    private let questions: QuizQuestionStore
    private let profiles: ProfileStore
    private let auth: any Authenticating
    private let cloud: any CloudAccountStatus
    private let social: any SocialService
    private let logger = Logger(subsystem: "app.uvva", category: "app")

    /// The Splash shows at least one full turn of its seven bunches (ONB-R01).
    static let minimumSplash = Duration.milliseconds(1260)

    init(container: ModelContainer) {
        maps = PalateMapStore(modelContainer: container)
        questions = QuizQuestionStore(modelContainer: container)
        profiles = ProfileStore(modelContainer: container)
        #if DEBUG
        if DemoMode.isOn {
            auth = DemoAuth()
            cloud = DemoCloud()
            social = DemoSocial()
            return
        }
        #endif
        auth = AppleAuthProvider()
        cloud = ICloudAccountStatus()
        social = CloudKitSocialService()
    }

    /// After the Splash (ONB-R02). A revoked Apple credential ends the session.
    func start() async {
        guard route == .launching else { return }
        async let splash: Void = (try? await Task.sleep(for: Self.minimumSplash)) ?? ()
        var profile = try? await profiles.currentProfile()
        if let current = profile, !(await auth.isStillAuthorized(current.authUserID)) { profile = nil }
        let hasMap = ((try? await maps.currentMap()) ?? nil) != nil
        await splash
        self.profile = profile
        switch LaunchRoute.resolve(profile: profile, hasMap: hasMap) {
        case .welcome: openOnboarding()
        case .quiz: openQuiz(.firstMap)
        case .home: route = .tabs(showTour: false)
        }
    }

    private func openOnboarding() {
        onboarding = OnboardingViewModel(auth: auth, profiles: profiles, maps: maps, social: social, cloud: cloud,
                                         contacts: DeviceContacts()) { [weak self] result in
            self?.finishOnboarding(result)
        }
        route = .onboarding
    }

    /// ONB-R21, R27
    private func finishOnboarding(_ result: OnboardingResult) {
        onboarding = nil
        switch result {
        case let .newAccount(profile):
            self.profile = profile
            openQuiz(.firstMap)
        case let .existingAccount(profile, hasMap):
            self.profile = profile
            if hasMap { route = .tabs(showTour: false) } else { openQuiz(.firstMap) }
        }
    }

    func openQuiz(_ entry: QuizEntry) {
        quiz = QuizViewModel(entry: entry, firstName: profile?.firstName, questions: questions, maps: maps) { [weak self] exit in
            self?.finishQuiz(exit)
        }
        route = .quiz(entry)
    }

    /// QUIZ-R25. The tour shows once per account (HOME-R29).
    private func finishQuiz(_ exit: QuizExit) {
        quiz = nil
        publishPublicProfile()
        switch exit {
        case .homeWithTour: route = .tabs(showTour: !(profile?.seenTours.contains("home") ?? false))
        case .youMap: route = .tabs(showTour: false)
        }
    }

    /// The map changed: friends see the new one (ARCHITECTURE §4.4). Best effort; the next change tries again.
    private func publishPublicProfile() {
        guard let profile else { return }
        let maps = maps
        let social = social
        let logger = logger
        Task.detached {
            let map = try? await maps.currentMap()
            do {
                try await social.publish(PublicProfile(id: profile.id, firstName: profile.firstName,
                                                       map: profile.mapIsPublic ? map : nil, hasMap: map != nil))
            } catch {
                logger.info("Public profile not published: \(error.localizedDescription)")
            }
        }
    }
}
