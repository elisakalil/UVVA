import Cellar
import CoreUI
import Core
import DesignSystem
import Friends
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
    private(set) var cellarTab: CellarViewModel?
    private(set) var friends: FriendsViewModel?
    /// The originating feature presents the note (CELLAR-R14).
    private(set) var newNote: (origin: AppTab, model: NewNoteViewModel)?
    /// The open note came from the Hero's "Add to cellar": once saved, the Home goes back to its top (HOME-R10c).
    private var newNoteReturnsHomeToTop = false
    private(set) var profile: Profile?
    private var isOpeningCourse = false
    private var navigationTask: Task<Void, Never>?
    private var prefetchTask: Task<Void, Never>?
    
    var launchError: String?
    var selectedTab: AppTab = .home

    private let maps: PalateMapStore
    private let questions: QuizQuestionStore
    private let profiles: ProfileStore
    private let catalog: CatalogStore
    private let courses: CatalogStore
    private let reminders: ReminderStore
    private let cellar: CellarStore
    private let learning: LearningStore
    private let friendsStore: FriendsStore
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
        courses = stores.courses
        reminders = stores.reminders
        cellar = stores.cellar
        learning = stores.learning
        friendsStore = stores.friends

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
            courses: courses,
            learning: learning,
            friends: friendsStore
        ).makeViewModel(coordinator: HomeCoordinator(
            onOpenCourse: { [weak self] id in
                self?.openCourse(id)
            },
            onOpenLearn: { [weak self] kind in
                self?.openLearn(kind)
            },
            onOpenLesson: { [weak self] suggestion in
                self?.openCourse(suggestion.courseID, lessonID: suggestion.lessonID)
            },
            onScan: { [weak self] in self?.openNewNote(from: .home) },
            onOpenCellarNote: { [weak self] wine, ratedVerdict, fromHero in
                self?.openNewNote(from: .home, for: wine, ratedVerdict: ratedVerdict, returnsHomeToTop: fromHero)
            },
            onOpenFriends: { [weak self] in self?.openFriendsSelection() },
            onOpenLastTable: { [weak self] in self?.openLastTable() },
            onOpenMapHistory: { [weak self] in self?.openMapHistory() }
        ))

        you = you ?? makeYou()

        cellarTab = cellarTab ?? cellarFactory.makeViewModel(
            onAdd: { [weak self] in self?.openNewNote(from: .cellar) },
            onNoteChange: { [weak self] in self?.noteChanged() },
            // CELLAR-R27: Edit on a saved note opens it in the new note.
            onEditNote: { [weak self] entry, wine in self?.openNewNote(from: .cellar, for: wine, editing: entry) })

        friends = friends ?? FriendsFactory(profiles: profiles, maps: maps, friends: friendsStore, catalog: catalog,
                                            social: social, contacts: DeviceContacts())
            .makeViewModel(onFriendsChange: { [weak self] in
                guard let home = self?.home else { return }
                Task { await home.load() }
            })

        learn = learn ?? LearnFactory(
            catalog: courses,
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
        prefetchTabs()
    }

    /// The Cellar, You and Friends read their data while the Home shows, so each opens complete on the first visit
    /// instead of flashing an empty state. The reads suspend without holding the main thread.
    private func prefetchTabs() {
        prefetchTask?.cancel()
        let (cellar, you, friends) = (cellarTab, you, friends)
        prefetchTask = Task(priority: .utility) {
            async let readCellar: Void = cellar?.prefetch() ?? ()
            async let readYou: Void = you?.prefetch() ?? ()
            async let readFriends: Void = friends?.prefetch() ?? ()
            _ = await (readCellar, readYou, readFriends)
        }
    }

    private var cellarFactory: CellarFactory {
        CellarFactory(cellar: cellar, maps: maps, rewriter: maps, wines: catalog)
    }

    /// CELLAR-R14: the same new note from the Home and the Cellar. With a wine, from the Home's Hero or wine sheet, it
    /// opens on paper with that wine, asking about it; "Rate it again?" when it was rated before (CELLAR-R14a).
    /// `returnsHomeToTop`: the note comes from the Hero, and the Home goes back to its top once it is saved.
    private func openNewNote(from origin: AppTab, for wine: Wine? = nil, ratedVerdict: Verdict? = nil,
                             editing: CellarEntry? = nil, returnsHomeToTop: Bool = false) {
        guard newNote == nil else { return }
        newNoteReturnsHomeToTop = returnsHomeToTop
        let model = NewNoteViewModel(
            wine: wine, ratedVerdict: ratedVerdict, editing: editing,
            cellar: cellar, maps: maps, labelCatalog: catalog, reader: VisionLabelReader(),
            structurer: DeviceLabelStructurer(), camera: DeviceCamera(), rewriter: maps, wines: catalog,
            onSaved: { [weak self] in self?.newNoteSaved() })
        newNote = (origin, model)
    }

    func closeNewNote(from origin: AppTab) {
        guard newNote?.origin == origin else { return }
        newNote = nil
    }

    /// Both tabs refresh after a save, while the note closes over its originating tab.
    private func newNoteSaved() {
        newNote = nil
        cellarTab?.newNoteSaved()
        // The match of every wine and "A wine for each strong trait" follow the new rating: the whole Home is read
        // again, under the curtain of every card. A note from the Hero also takes the Home back to its top.
        let returnsToTop = newNoteReturnsHomeToTop
        newNoteReturnsHomeToTop = false
        Task { await home?.reload(returningToTop: returnsToTop) }
        publishPublicProfile()
    }

    /// FRI-R20: "Set a table with your friends" opens the choice of who comes.
    private func openFriendsSelection() {
        selectedTab = .friends
        friends?.startSelecting()
    }

    /// HOME-R11: the match card opens the last table, in the Friends tab (FRI-R17).
    private func openLastTable() {
        selectedTab = .friends
        guard let friends else { return }
        Task { await friends.openLastTable() }
    }

    /// HOME-R17: the "axis that changed" card opens You › Map, at "Over time" (YOU-R03).
    private func openMapHistory() {
        you?.showMapHistory()
        withAnimation(.easeInOut(duration: 0.35)) { selectedTab = .you }
    }

    private func makeYou() -> YouViewModel {
        YouFactory(profiles: profiles, maps: maps, catalog: catalog, courses: courses, learning: learning, social: social,
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

    /// HOME-R10c: a note edited or deleted in the Cellar may have moved the map. The Home is not read now: it reads
    /// its Hero and "Wines for your palate" again, under their curtain, the next time it is shown.
    private func noteChanged() {
        guard let home else { return }
        home.palateChanged()
        if selectedTab == .home { Task { await home.loadIfNeeded() } }
    }

    private func learningChanged() {
        Task { await home?.load() }
        // You reloads on entry. Refresh immediately if it is already visible.
        if selectedTab == .you, let you {
            Task { await you.load() }
        }
    }

    private func resetTabs() {
        prefetchTask?.cancel()
        prefetchTask = nil
        isOpeningCourse = false
        profile = nil
        home = nil
        you = nil
        learn = nil
        cellarTab = nil
        friends = nil
        newNote = nil
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
