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
    /// FRI-R06: the Onboarding's contacts list, opened over the Friends tab.
    private(set) var addFriends: AddFriendsModule?
    /// The originating feature presents the note (CELLAR-R14).
    private(set) var newNote: (origin: AppTab, model: NewNoteViewModel)?
    /// WINELIST-R01: the Home's scan reads a label or a restaurant's wine list; the list's side of the sheet.
    private(set) var wineList: WineListViewModel?
    /// The open note came from the Hero's "Add to cellar": once saved, the Home goes back to its top (HOME-R10c).
    private var newNoteReturnsHomeToTop = false
    private(set) var profile: Profile?
    private var isOpeningCourse = false
    private var navigationTask: Task<Void, Never>?
    private var prefetchTask: Task<Void, Never>?
    /// The tabs are loading under the Splash: a change of friends is read with the Home there, not after.
    private var isLoadingTabs = false
    private var friendsChangedWhileLoading = false
    /// The user has friends, found under the Splash: notifications are asked for once it has faded out.
    private var pushesAwaitReveal = false
    
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
    private let notifications: NotificationStore
    private let scheduler = LocalReminderScheduler()
    private let auth: any Authenticating
    private let cloud: any CloudAccountStatus
    private let social: any SocialService
    private let catalogSync: CatalogSync
    private let logger = Logger(subsystem: "app.uvva", category: "app")
    private let content: ContentLoader

    static let minimumSplash = Duration.milliseconds(1260)
    /// The longest the Splash waits for what depends on the network (friends, the day's catalog changes, the
    /// contributions); past it they finish behind the tabs. What is read from the phone is always waited for.
    static let networkWaitLimit = Duration.seconds(8)
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
        notifications = stores.notifications

        auth = AppleAuthProvider()
        cloud = ICloudAccountStatus()
        social = stores.social
        catalogSync = stores.catalogSync
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
                                         contacts: DeviceContacts(), friends: friendsStore).makeModule { [weak self] result in
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

        let model = QuizFactory(questions: questions, maps: maps, catalog: catalog).makeViewModel(
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

        if quizExit == .youMap { home = nil }
        home = home ?? HomeFactory(
            profiles: profiles,
            maps: maps,
            catalog: catalog,
            cellar: cellar,
            courses: courses,
            learning: learning,
            friends: friendsStore,
            notifications: notifications,
            social: social,
            sharing: social as? any WineSharingService
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
            onScan: { [weak self] in self?.openNewNote(from: .home, readsWineList: true) },
            onOpenCellarNote: { [weak self] wine, ratedVerdict, fromHero in
                self?.openNewNote(from: .home, for: wine, ratedVerdict: ratedVerdict, returnsHomeToTop: fromHero)
            },
            onOpenFriends: { [weak self] in self?.openFriendsSelection() },
            onOpenFriendTable: { [weak self] id in self?.openFriendTable(id) },
            onOpenFriend: { [weak self] id in self?.openFriendProfile(id) },
            onOpenMapHistory: { [weak self] in self?.openMapHistory() },
            onOpenFriendRequests: { [weak self] in self?.openFriendRequests() },
            onOpenReceivedWine: { [weak self] id in self?.openSharedWine(id) },
            onWineAddedToCellar: { [weak self] wineKey in self?.cellarTab?.refreshEntry(wineKey) }
        ))

        you = you ?? makeYou()

        cellarTab = cellarTab ?? cellarFactory.makeViewModel(
            onAdd: { [weak self] in self?.openNewNote(from: .cellar) },
            onNoteChange: { [weak self] in self?.noteChanged() },
            // CELLAR-R27: Edit on a saved note opens it in the new note.
            onEditNote: { [weak self] entry, wine in self?.openNewNote(from: .cellar, for: wine, editing: entry) })

        friends = friends ?? FriendsFactory(profiles: profiles, maps: maps, friends: friendsStore, catalog: catalog,
                                            social: social, contacts: DeviceContacts(), cellar: cellar,
                                            sharing: social as? any WineSharingService, wines: catalog,
                                            makeWineScan: { [cellar, maps, catalog] onScanned in
                                                // FRI-R12a: the new note's camera and reading, scan only.
                                                Self.makeWineScan(cellar: cellar, maps: maps, catalog: catalog,
                                                                  onScanned: onScanned)
                                            })
            .makeViewModel(onFriendsChange: { [weak self] in
                guard let self, let home = self.home else { return }
                if self.isLoadingTabs {
                    self.friendsChangedWhileLoading = true
                } else {
                    Task { await home.load() }
                }
            }, onAddFriends: { [weak self] in self?.openAddFriends() },
            // FRI-R11c: "Add to cellar" on a wine a friend sent opens the same new note as the Home.
            onAddToCellar: { [weak self] wine in self?.openNewNote(from: .friends, for: wine) },
            onHasFriends: { [weak self] in self?.friendsFound() })
        // FRI-R11c: a tapped push opens the wine in the Friends tab, now or once it is there.
        SharedWinePushes.shared.onOpen = { [weak self] id in self?.openSharedWine(id) }

        learn = learn ?? LearnFactory(
            catalog: courses,
            learning: learning,
            profiles: profiles
        ).makeViewModel(onProgressChange: { [weak self] in
                self?.learningChanged()
            }
        )

        // ONB-R01: everything the tabs show loads under the Splash, at once and off the main thread, so the Home is
        // usable as soon as it is seen: the Home itself, the Cellar, You and Friends, the day's catalog changes and the
        // contributions. Nothing of it is left to start behind the Home.
        isLoadingTabs = true
        friendsChangedWhileLoading = false
        defer { isLoadingTabs = false }
        let others = Task { await self.loadOtherTabs() }
        prefetchTask = others
        try await withTaskCancellationHandler {
            try await self.home?.prepare()
        } onCancel: {
            others.cancel()
        }
        try Task.checkCancellation()
        await Self.wait(for: others, atMost: Self.networkWaitLimit)
        try Task.checkCancellation()
        // A friend came or left while the Home was read: it is read again, still under the Splash.
        if friendsChangedWhileLoading {
            friendsChangedWhileLoading = false
            await home?.load()
        }
        await home?.refreshNotifications()
        try Task.checkCancellation()

        if quizExit == .youMap {
            // The redone Quiz replaced the map: You › Map opens on the new one, not the one You still holds.
            await you?.reloadMap()
            try Task.checkCancellation()
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

    /// The Splash has faded out over the next screen. Only what asks the user waits for this (the notifications);
    /// over the Onboarding, the catalog import starts, as the Onboarding has nothing to wait for it.
    func splashRevealed() {
        content.screenRevealed()
        if pushesAwaitReveal, route != .launching {
            pushesAwaitReveal = false
            prepareSharedWinePushes()
        }
    }

    /// FRI-R11c: with a friend, notifications are asked for; never over the Splash.
    private func friendsFound() {
        if route == .launching || isLoadingTabs {
            pushesAwaitReveal = true
        } else {
            prepareSharedWinePushes()
        }
    }

    /// The Cellar, You and Friends read their data under the Splash, alongside the Home, so each opens complete on
    /// the first visit; the day's catalog changes and the contributions go then too. The reads run on the stores'
    /// own queues; only their results come back to the main thread.
    private func loadOtherTabs() async {
        let (cellar, you, friends, content) = (cellarTab, you, friends, content)
        async let readCellar: Void = cellar?.prefetch() ?? ()
        async let readYou: Void = you?.prefetch() ?? ()
        async let readFriends: Void = friends?.prefetch() ?? ()
        async let syncCatalog: Void = content.waitForDailySync()
        async let contribute: Void = contributions()
        _ = await (readCellar, readYou, readFriends, syncCatalog, contribute)
    }

    /// Waits for `work` or for `limit`, whichever comes first; the work goes on after.
    private static func wait(for work: Task<Void, Never>, atMost limit: Duration) async {
        let race = LaunchRace()
        await withCheckedContinuation { continuation in
            race.continuation = continuation
            race.timer = Task { @MainActor in
                try? await Task.sleep(for: limit)
                race.finish()
            }
            Task { @MainActor in
                await work.value
                race.finish()
            }
        }
    }

    private var cellarFactory: CellarFactory {
        CellarFactory(cellar: cellar, maps: maps, rewriter: maps, wines: catalog, labelCatalog: catalog)
    }

    /// CELLAR-R14: the same new note from the Home and the Cellar. With a wine, from the Home's Hero or wine sheet, it
    /// opens on paper with that wine, asking about it; "Rate it again?" when it was rated before (CELLAR-R14a).
    /// `returnsHomeToTop`: the note comes from the Hero, and the Home goes back to its top once it is saved.
    /// `readsWineList`: the Home's `+`, where the camera also reads a restaurant's wine list (WINELIST-R01).
    private func openNewNote(from origin: AppTab, for wine: Wine? = nil, ratedVerdict: Verdict? = nil,
                             editing: CellarEntry? = nil, returnsHomeToTop: Bool = false,
                             readsWineList: Bool = false) {
        guard newNote == nil else { return }
        newNoteReturnsHomeToTop = returnsHomeToTop
        wineList = readsWineList ? makeWineList() : nil
        let model = NewNoteViewModel(
            wine: wine, ratedVerdict: ratedVerdict, editing: editing,
            cellar: cellar, maps: maps, labelCatalog: catalog, reader: VisionLabelReader(),
            structurer: DeviceLabelStructurer(), pairer: DevicePairingSuggester(),
            wordChecker: DeviceChipWordChecker(), camera: DeviceCamera(),
            rewriter: maps, wines: catalog,
            onSaved: { [weak self] wineKey in self?.newNoteSaved(wineKey) })
        newNote = (origin, model)
    }

    /// WINELIST.md: the wine list of a restaurant, read by the camera and ranked for tonight.
    private func makeWineList() -> WineListViewModel {
        WineListViewModel(maps: maps, friends: friendsStore, recipes: catalog, labelCatalog: catalog,
                          reader: VisionWineListReader(), camera: DeviceCamera(),
                          onAddToCellar: { [weak self] wine in self?.wineListOrdered(wine) })
    }

    /// WINELIST-R08: the wine ordered from the list goes to a new note, on paper, as from the Home's wine sheet. The
    /// scan's sheet closes first, as it was; the note opens once it is gone. Each `+` makes the list anew.
    private func wineListOrdered(_ wine: Wine) {
        newNote = nil
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            self?.openNewNote(from: .home, for: wine)
        }
    }

    /// FRI-R11c: with a friend, the user is asked for notifications, and the wines sent to them push.
    private func prepareSharedWinePushes() {
        guard let sharing = social as? any WineSharingService else { return }
        Task { [profiles] in
            guard let userID = try? await profiles.currentProfile()?.id else { return }
            await SharedWinePushes.shared.prepare(userID: userID, sharing: sharing)
        }
    }

    /// FRI-R11c: a tapped push opens the wine sent, full screen over the Friends tab.
    private func openSharedWine(_ id: String) {
        selectedTab = .friends
        guard let friends else { return }
        Task { await friends.openReceived(id) }
    }

    /// FRI-R12a: the new note's camera and label reading, handing over the wine it reads instead of saving a note.
    private static func makeWineScan(cellar: CellarStore, maps: PalateMapStore, catalog: CatalogStore,
                                     onScanned: @escaping (Wine) -> Void) -> NewNoteViewModel {
        NewNoteViewModel(
            cellar: cellar, maps: maps, labelCatalog: catalog, reader: VisionLabelReader(),
            structurer: DeviceLabelStructurer(), pairer: DevicePairingSuggester(),
            wordChecker: DeviceChipWordChecker(), camera: DeviceCamera(),
            rewriter: maps, wines: catalog, onScanned: onScanned, onSaved: { _ in })
    }

    func closeNewNote(from origin: AppTab) {
        guard newNote?.origin == origin else { return }
        newNote = nil
    }

    /// Both tabs refresh after a save, while the note closes over its originating tab.
    private func newNoteSaved(_ wineKey: String) {
        newNote = nil
        cellarTab?.newNoteSaved(wineKey)
        // The match of every wine and "A wine for each strong trait" follow the new rating: the whole Home is read
        // again, under the curtain of every card. A note from the Hero also takes the Home back to its top.
        let returnsToTop = newNoteReturnsHomeToTop
        newNoteReturnsHomeToTop = false
        Task { await home?.reload(returningToTop: returnsToTop) }
        publishPublicProfile()
        sendContributions()
    }

    /// The labels read and not yet in the public catalog go to it as this user's contributions (ARCHITECTURE §4.3).
    /// Without an iCloud account or a network they wait for the next note or launch.
    private func sendContributions() {
        Task { await contributions() }
    }

    private func contributions() async {
        guard let userID = profile?.id else { return }
        let sync = catalogSync
        let logger = logger
        await Task.detached(priority: .utility) {
            do {
                try await sync.sendContributions(userID: userID)
            } catch {
                logger.info("Contributions wait: \(error.localizedDescription, privacy: .public)")
            }
        }.value
    }

    /// FRI-R06: "Add friends to compare maps" opens the contacts list of the Onboarding, for the user's account.
    private func openAddFriends() {
        guard let profile else { return }
        addFriends = OnboardingFactory(auth: auth, profiles: profiles, maps: maps, social: social, cloud: cloud,
                                       contacts: DeviceContacts(), friends: friendsStore)
            .makeAddFriends(profile: profile) { [weak self] in self?.closeAddFriends() }
    }

    /// Closing reads the friends again: the requests just sent show as "Requested" in Quick add.
    func closeAddFriends() {
        addFriends = nil
        guard let friends else { return }
        Task { await friends.reload() }
    }

    /// HOME-R04b: a friend request notification opens the Friends tab, read again so the request the Home just saw is
    /// there to answer (FRI-R08a).
    private func openFriendRequests() {
        selectedTab = .friends
        guard let friends else { return }
        Task { await friends.reload() }
    }

    /// FRI-R20: "Set a table with your friends" opens the choice of who comes.
    private func openFriendsSelection() {
        selectedTab = .friends
        friends?.startSelecting()
    }

    /// HOME-R11: the match card opens the table with that friend, in the Friends tab (FRI-R13).
    private func openFriendTable(_ id: String) {
        selectedTab = .friends
        guard let friends else { return }
        Task { await friends.openFriendTable(id) }
    }

    /// HOME-R04b: a new-friend notification opens only that friend's profile, in the Friends tab, with no table set.
    private func openFriendProfile(_ id: String) {
        selectedTab = .friends
        guard let friends else { return }
        Task { await friends.openFriendProfile(id) }
    }

    /// HOME-R17: the "axis that changed" card opens You › Map, at "Over time" (YOU-R03).
    private func openMapHistory() {
        you?.showMapHistory()
        selectedTab = .you
    }

    private func makeYou() -> YouViewModel {
        YouFactory(profiles: profiles, maps: maps, catalog: catalog, courses: courses, learning: learning, social: social,
                     reminders: reminders, scheduler: scheduler, cellar: cellar)
            .makeViewModel(coordinator: YouCoordinator(
                     onRedoMap: { [weak self] in self?.openQuiz(.redo) },
                     onOpenLearn: { [weak self] in self?.selectedTab = .learn },
                     onOpenCourse: { [weak self] id in self?.openCourse(id) },
                     onOpenCertificate: { [weak self] id in
                         guard let learn = self?.learn else { return }
                         Task { await learn.showCertificate(courseID: id) }
                     },
                     onSignOut: { [weak self] in self?.signOut() },
                     onAccountDeleted: { [weak self] in self?.accountDeleted() },
                     onOpenWine: { [weak self] id in self?.openCellarNote(id) }))
    }

    /// YOU-R07a: a wine picked from a place of the Progress map opens its note in the Cellar.
    private func openCellarNote(_ wineKey: String) {
        selectedTab = .cellar
        cellarTab?.openNote(wineKey)
    }

    private func signOut() {
        UserDefaults.standard.set(true, forKey: Self.signedOutKey)
        resetTabs()
        openOnboarding()
    }

    private func accountDeleted() {
        UserDefaults.standard.removeObject(forKey: Self.signedOutKey)
        let sync = catalogSync
        Task.detached { try? await sync.forgetContributions() }
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
        friendsChangedWhileLoading = false
        pushesAwaitReveal = false
        isOpeningCourse = false
        profile = nil
        home = nil
        you = nil
        learn = nil
        cellarTab = nil
        friends = nil
        addFriends = nil
        newNote = nil
        wineList = nil
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

/// The first of two tasks to finish resumes the wait (`AppCoordinator.wait(for:atMost:)`).
@MainActor
private final class LaunchRace {
    var continuation: CheckedContinuation<Void, Never>?
    var timer: Task<Void, Never>?

    func finish() {
        timer?.cancel()
        continuation?.resume()
        continuation = nil
    }
}
