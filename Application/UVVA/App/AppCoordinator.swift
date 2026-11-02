import Core
import DesignSystem
import Features
import Foundation
import Observation
import OSLog
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
    private(set) var home: HomeViewModel?
    /// The Home tour, while it runs (HOME-R29).
    private(set) var tour: GuidedTourViewModel?
    private(set) var you: YouViewModel?
    private(set) var learn: LearnViewModel?
    /// The tab on screen; features move it through the coordinator (APP-R06).
    var selectedTab: AppTab = .home
    private(set) var profile: Profile?

    private let maps: PalateMapStore
    private let questions: QuizQuestionStore
    private let profiles: ProfileStore
    private let catalog: CatalogStore
    private let reminders: ReminderStore
    private let cellar: CellarStore
    private let learning: LearningStore
    private let scheduler = LocalReminderScheduler()
    private let auth: any Authenticating
    private let cloud: any CloudAccountStatus
    private let social: any SocialService
    private let logger = Logger(subsystem: "app.uvva", category: "app")

    /// The Splash shows at least one full turn of its seven bunches (ONB-R01).
    static let minimumSplash = Duration.milliseconds(1260)
    /// Set by "Sign out" (YOU-R26): the data stays, but the app opens on the Welcome until the next sign-in.
    static let signedOutKey = "session.signedOut"

    init(stores: AppStores) {
        maps = stores.maps
        questions = stores.questions
        profiles = stores.profiles
        catalog = stores.catalog
        reminders = stores.reminders
        cellar = stores.cellar
        learning = stores.learning
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

    /// After the Splash (ONB-R02). A revoked Apple credential, or "Sign out", ends the session.
    func start() async {
        guard route == .launching else { return }
        timingLog.info("TIMING start() begin")
        async let splash: Void = (try? await Task.sleep(for: Self.minimumSplash)) ?? ()
        // Ready before the first screen with glass, so building it does not freeze the Splash.
        async let glass: Void = GlassTextures.prepare()
        var profile = try? await profiles.currentProfile()
        timingLog.info("TIMING profile fetched")
        if let current = profile, !(await auth.isStillAuthorized(current.authUserID)) { profile = nil }
        if UserDefaults.standard.bool(forKey: Self.signedOutKey) { profile = nil }
        let hasMap = ((try? await maps.currentMap()) ?? nil) != nil
        timingLog.info("TIMING map fetched")
        await splash
        timingLog.info("TIMING splash min done")
        await glass
        timingLog.info("TIMING glass ready")
        self.profile = profile
        switch LaunchRoute.resolve(profile: profile, hasMap: hasMap) {
        case .welcome: openOnboarding()
        case .quiz: openQuiz(.firstMap)
        case .home:
            // A tour left before "Start" shows again on the next launch: it only counts as seen at the end
            // (HOME-R33, decided 2026-10-31).
            let tourPending = !(profile?.seenTours.contains(GuidedTour.tourID) ?? true)
            openTabs(after: tourPending ? .homeWithTour : nil)
        }
    }

    private func openOnboarding() {
        onboarding = OnboardingViewModel(auth: auth, profiles: profiles, maps: maps, social: social, cloud: cloud,
                                         contacts: DeviceContacts()) { [weak self] result in
            self?.finishOnboarding(result)
        }
        route = .onboarding
        timingLog.info("TIMING route onboarding")
    }

    /// ONB-R21, R27
    private func finishOnboarding(_ result: OnboardingResult) {
        onboarding = nil
        UserDefaults.standard.removeObject(forKey: Self.signedOutKey)
        switch result {
        case let .newAccount(profile):
            self.profile = profile
            openQuiz(.firstMap)
        case let .existingAccount(profile, hasMap):
            self.profile = profile
            restoreReminder()
            if hasMap { openTabs(after: nil) } else { openQuiz(.firstMap) }
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
        openTabs(after: exit)
    }

    /// The tabs. The tour shows after the first map, once per account (HOME-R29); a redone map opens You › Map.
    private func openTabs(after quizExit: QuizExit?) {
        home = home ?? HomeViewModel(profiles: profiles, maps: maps, catalog: catalog, cellar: cellar, courses: catalog,
                                     learning: learning,
                                     onOpenCourse: { [weak self] id in self?.openCourse(id) },
                                     onOpenLearn: { [weak self] kind in self?.openLearn(kind) })
        you = you ?? makeYou()
        learn = learn ?? LearnViewModel(catalog: catalog, learning: learning, profiles: profiles,
                                        onProgressChange: { [weak self] in self?.learningChanged() })
        if quizExit == .youMap {
            selectedTab = .you
            you?.tab = .map
        }
        let showTour = GuidedTour.shouldShow(quizExit: quizExit, seenTours: profile?.seenTours ?? [])
        tour = showTour ? GuidedTourViewModel(firstName: profile?.firstName ?? "") { [weak self] in self?.finishTour() } : nil
        route = .tabs(showTour: showTour)
        Task {
            await home?.load()
            await you?.load()
        }
    }

    private func makeYou() -> YouViewModel {
        YouViewModel(profiles: profiles, maps: maps, catalog: catalog, courses: catalog, learning: learning, social: social,
                     reminders: reminders, scheduler: scheduler,
                     onRedoMap: { [weak self] in self?.openQuiz(.redo) },
                     onOpenLearn: { [weak self] in self?.selectedTab = .learn },
                     onOpenCourse: { [weak self] id in self?.openCourse(id) },
                     onOpenCertificate: { [weak self] id in
                         guard let learn = self?.learn else { return }
                         Task { await learn.showCertificate(courseID: id) }
                     },
                     onSignOut: { [weak self] in self?.signOut() },
                     onAccountDeleted: { [weak self] in self?.accountDeleted() })
    }

    /// YOU-R26: back to the Welcome; signing in again finds everything (ONB-R27).
    private func signOut() {
        UserDefaults.standard.set(true, forKey: Self.signedOutKey)
        resetTabs()
        openOnboarding()
    }

    /// YOU-R27: the data is gone; the same Apple account starts as a new one.
    private func accountDeleted() {
        UserDefaults.standard.removeObject(forKey: Self.signedOutKey)
        resetTabs()
        openOnboarding()
    }

    /// Home and You open Learn (APP-R06): a tab (LEARN-R04), or a course with its lesson (LEARN-R11).
    private func openLearn(_ kind: CourseKind) {
        learn?.show(kind)
        selectedTab = .learn
    }

    private func openCourse(_ id: String) {
        selectedTab = .learn
        guard let learn else { return }
        Task { await learn.openCourse(id: id) }
    }

    /// A lesson saved or a course finished: the Home's "Continue" and You's numbers follow.
    private func learningChanged() {
        Task {
            await home?.load()
            await you?.load()
        }
    }

    private func resetTabs() {
        profile = nil
        home = nil
        you = nil
        learn = nil
        tour = nil
        selectedTab = .home
    }

    /// An account found again brings its reminder back to this device.
    private func restoreReminder() {
        let reminders = reminders
        let scheduler = scheduler
        Task { await scheduler.schedule(try? await reminders.reminder()) }
    }

    /// HOME-R33: the tour closes and is marked seen on the account.
    private func finishTour() {
        tour = nil
        profile?.seenTours.insert(GuidedTour.tourID)
        let profiles = profiles
        Task { try? await profiles.markTourSeen(GuidedTour.tourID) }
    }

    /// The import ended: the Home, Learn and You can show the catalog now.
    func contentDidLoad() {
        Task {
            await home?.load()
            await learn?.load()
            await you?.load()
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
