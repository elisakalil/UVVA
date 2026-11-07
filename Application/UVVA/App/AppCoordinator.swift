import Core
import DesignSystem
import SwiftUI
import Home
import Learn
import Onboarding
import OSLog
import Quizz
import Storage
import You

@MainActor @Observable
final class AppCoordinator {
    private(set) var route: AppRoute = .launching
    private(set) var onboarding: OnboardingModule?
    private(set) var quiz: QuizViewModel?
    private(set) var home: HomeViewModel?
    private(set) var tour: GuidedTourViewModel?
    private(set) var you: YouViewModel?
    private(set) var learn: LearnViewModel?
    private(set) var profile: Profile?
    private var isOpeningCourse = false
    private var navigationTask: Task<Void, Never>?
    
    var launchError: String?
    var selectedTab: AppTab = .home

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
    private let content: ContentLoader

    static let minimumSplash = Duration.milliseconds(1260)
    static let signedOutKey = "session.signedOut"

    init(stores: AppStores, content: ContentLoader) {
        self.content = content

        maps = stores.maps
        questions = stores.questions
        profiles = stores.profiles
        catalog = stores.catalog
        reminders = stores.reminders
        cellar = stores.cellar
        learning = stores.learning

        auth = AppleAuthProvider()
        cloud = ICloudAccountStatus()
        social = stores.social
    }
    
    func start() async throws {
        guard route == .launching else { return }

        var current = try await profiles.currentProfile()

        if UserDefaults.standard.bool(forKey: Self.signedOutKey) {
            current = nil
        } else if let saved = current,
                  !(await auth.isStillAuthorized(saved.authUserID)) {
            current = nil
        }

        let hasMap: Bool
        if current == nil {
            hasMap = false
        } else {
            hasMap = try await maps.currentMap() != nil
        }

        try Task.checkCancellation()
        profile = current

        switch LaunchRoute.resolve(profile: current, hasMap: hasMap) {
        case .welcome:
            openOnboarding()

        case .quiz:
            try await prepareQuiz(.firstMap)

        case .home:
            let tourPending = !(
                current?.seenTours.contains(GuidedTour.tourID) ?? true
            )
            try await prepareTabs(
                after: tourPending ? .homeWithTour : nil
            )
        }
    }

    private func openOnboarding() {
        onboarding = OnboardingFactory(auth: auth, profiles: profiles, maps: maps, social: social, cloud: cloud,
                                         contacts: DeviceContacts()).makeModule { [weak self] result in
            self?.finishOnboarding(result)
        }
        route = .onboarding
    }

    private func finishOnboarding(_ result: OnboardingResult) {
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
        navigate {
            try await self.prepareQuiz(entry)
        }
    }

    private func prepareQuiz(_ entry: QuizEntry) async throws {
        try await content.waitForQuestions()

        let model = QuizFactory(questions: questions, maps: maps).makeViewModel(
            entry: entry, firstName: profile?.firstName,
            coordinator: QuizCoordinator(entry: entry) { [weak self] exit in
                self?.finishQuiz(exit)
            }
        )

        try await model.prepare()
        try Task.checkCancellation()

        quiz = model
        onboarding = nil
        route = .quiz(entry)
    }

    private func finishQuiz(_ exit: QuizExit) {
        publishPublicProfile()
        openTabs(after: exit)
    }

    private func openTabs(after quizExit: QuizExit?) {
        navigate {
            try await self.prepareTabs(after: quizExit)
        }
    }

    private func prepareTabs(after quizExit: QuizExit?) async throws {
        try await content.waitUntilReady()

        home = home ?? HomeFactory(
            profiles: profiles,
            maps: maps,
            catalog: catalog,
            cellar: cellar,
            courses: catalog,
            learning: learning
        ).makeViewModel(coordinator: HomeCoordinator(
            onOpenCourse: { [weak self] id in
                self?.openCourse(id)
            },
            onOpenLearn: { [weak self] kind in
                self?.openLearn(kind)
            },
            onOpenLesson: { [weak self] suggestion in
                self?.openCourse(suggestion.courseID, lessonID: suggestion.lessonID)
            }
        ))

        you = you ?? makeYou()

        learn = learn ?? LearnFactory(
            catalog: catalog,
            learning: learning,
            profiles: profiles
        ).makeViewModel(onProgressChange: { [weak self] in
                self?.learningChanged()
            }
        )

        try await home?.prepare()
        try Task.checkCancellation()

        if quizExit == .youMap {
            selectedTab = .you
            you?.tab = .map
        } else {
            selectedTab = .home
        }

        let showTour = GuidedTour.shouldShow(
            quizExit: quizExit,
            seenTours: profile?.seenTours ?? []
        )

        tour = showTour
            ? GuidedTourViewModel(
                firstName: profile?.firstName ?? ""
            ) { [weak self] in
                self?.finishTour()
            }
            : nil

        onboarding = nil
        quiz = nil
        route = .tabs(showTour: showTour)
    }

    private func makeYou() -> YouViewModel {
        YouFactory(profiles: profiles, maps: maps, catalog: catalog, courses: catalog, learning: learning, social: social,
                     reminders: reminders, scheduler: scheduler)
            .makeViewModel(coordinator: YouCoordinator(
                     onRedoMap: { [weak self] in self?.openQuiz(.redo) },
                     onOpenLearn: { [weak self] in self?.selectedTab = .learn },
                     onOpenCourse: { [weak self] id in self?.openCourse(id) },
                     onOpenCertificate: { [weak self] id in
                         guard let learn = self?.learn else { return }
                         Task { await learn.showCertificate(courseID: id) }
                     },
                     onSignOut: { [weak self] in self?.signOut() },
                     onAccountDeleted: { [weak self] in self?.accountDeleted() }))
    }

    private func signOut() {
        UserDefaults.standard.set(true, forKey: Self.signedOutKey)
        resetTabs()
        openOnboarding()
    }

    private func accountDeleted() {
        UserDefaults.standard.removeObject(forKey: Self.signedOutKey)
        resetTabs()
        openOnboarding()
    }

    private func openLearn(_ kind: CourseKind) {
        learn?.show(kind)
        selectedTab = .learn
    }

    private func openCourse(_ id: String, lessonID: String? = nil) {
        guard let learn, !isOpeningCourse else { return }
        isOpeningCourse = true
        Task {
            await learn.openCourse(id: id, lessonID: lessonID)
            if learn.player == nil { isOpeningCourse = false }
        }
    }

    func lessonDidPresent() {
        guard isOpeningCourse else { return }
        isOpeningCourse = false
        selectedTab = .learn
    }

    private func learningChanged() {
        Task { await home?.load() }
        // You reloads on entry. Refresh immediately if it is already visible.
        if selectedTab == .you, let you {
            Task { await you.load() }
        }
    }

    private func resetTabs() {
        isOpeningCourse = false
        profile = nil
        home = nil
        you = nil
        learn = nil
        tour = nil
        selectedTab = .home
    }

    private func restoreReminder() {
        let reminders = reminders
        let scheduler = scheduler
        Task { await scheduler.schedule(try? await reminders.reminder()) }
    }

    private func finishTour() {
        tour = nil
        profile?.seenTours.insert(GuidedTour.tourID)
        let profiles = profiles
        Task { try? await profiles.markTourSeen(GuidedTour.tourID) }
    }

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
    
    private func navigate(
        _ operation: @escaping @MainActor () async throws -> Void
    ) {
        guard navigationTask == nil else { return }

        launchError = nil
        route = .launching

        navigationTask = Task {
            defer { navigationTask = nil }

            do {
                try await operation()
            } catch is CancellationError {
                return
            } catch {
                launchError = error.localizedDescription
            }
        }
    }

    func stop() async {
        navigationTask?.cancel()
        await content.stop()
        await navigationTask?.value
        navigationTask = nil
    }
}
