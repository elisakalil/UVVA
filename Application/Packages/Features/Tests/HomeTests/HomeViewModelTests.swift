import Combine
import Core
import Foundation
import Match
import Testing
@testable import Home
@testable import Learn
import Storage

private struct ProfilesStub: ProfileRepository {
    func currentProfile() async throws -> Profile? {
        Profile(id: "u1", authProvider: .apple, authUserID: "a", firstName: "Elisa", phone: nil)
    }
    func profile(authUserID: String, waitingUpTo timeout: Duration) async throws -> Profile? { nil }
    func save(_ profile: Profile) async throws {}
    func markTourSeen(_ tour: String) async throws {}
    func deleteAccount() async throws {}
}

private struct MapStub: PalateMapRepository {
    func currentMap() async throws -> PalateMap? { HomeContentModel.full.palateMap }
    func saveQuizMap(_ map: PalateMap, at date: Date) async throws {}
    func history() async throws -> [MapChange] { [] }
    func saveRatedMap(_ map: PalateMap, wineKey: String, verdict: Verdict, at date: Date) async throws {}
}

private struct CatalogStub: CatalogRepository {
    func winesClosest(to map: PalateMap, limit: Int) async throws -> [Wine] {
        Array(HomeContentModel.full.catalog.map { var wine = $0; wine.dish = nil; return wine }.prefix(limit))
    }
    func recipes() async throws -> [Recipe] {
        [Recipe(id: "stew", title: "Lamb stew", why: "Weight for weight.", course: "main", wineTypes: ["Red"],
                profile: PalateMap([.body: 7]),
                ingredients: [RecipeIngredient(name: "lamb", quantity: 800, unit: "g", note: nil, role: "base")],
                steps: ["Brown the lamb."])]
    }
    func glossary() async throws -> [GlossaryTerm] { HomeContentModel.full.glossary }
    func firstPathModule() async throws -> CourseSummary? { nil }
}

/// The catalog as the store gives it: ranked on the map it is asked for, equally close wines by their key.
private struct RankedCatalogStub: CatalogRepository {
    func winesClosest(to map: PalateMap, limit: Int) async throws -> [Wine] {
        let ranked = HomeContentModel.full.catalog
            .map { wine -> Wine in var wine = wine; wine.dish = nil; return wine }
            .sorted {
                let (l, r) = (Similarity.between($0.profile, map), Similarity.between($1.profile, map))
                return l == r ? $0.id < $1.id : l > r
            }
        return Array(ranked.prefix(limit))
    }
    func recipes() async throws -> [Recipe] { try await CatalogStub().recipes() }
    func glossary() async throws -> [GlossaryTerm] { HomeContentModel.full.glossary }
    func firstPathModule() async throws -> CourseSummary? { nil }
}

/// A map that a rating moves onto the rated wine, so the test can tell where the top of the list must go.
private actor MovingMapStub: PalateMapRepository {
    private var map: PalateMap
    init(map: PalateMap) { self.map = map }
    func currentMap() async throws -> PalateMap? { map }
    func saveQuizMap(_ map: PalateMap, at date: Date) async throws {}
    func history() async throws -> [MapChange] { [] }
    func saveRatedMap(_ map: PalateMap, wineKey: String, verdict: Verdict, at date: Date) async throws {
        self.map = HomeContentModel.full.catalog.first { $0.id == wineKey }?.profile ?? map
    }
}

private struct CoursesStub: CourseCatalog {
    static let tannat = Course(id: "grape-tannat", kind: .grape, order: 1, title: "Tannat", about: "",
                               lessons: (1...3).map {
                                   LessonSummary(id: "grape-tannat-l0\($0)", courseID: "grape-tannat", order: $0,
                                                 title: "Lesson \($0)", subtitle: "", xp: 15, minutes: 3, isReview: $0 == 3,
                                                 objectives: [])
                               })
    func courses(_ kind: CourseKind) async throws -> [Course] { kind == .grape ? [Self.tannat] : [] }
    func course(id: String) async throws -> Course? { id == Self.tannat.id ? Self.tannat : nil }
    func lesson(id: String) async throws -> Lesson? { nil }
}

private struct LearningStub: LearningRepository {
    func snapshot(for courses: [Course]) async throws -> LearningSnapshot { testSnapshot(courses, lessons: try await progress()) }
    func save(_ progress: LessonProgress, in course: Course) async throws { try await save(progress) }

    var saved: [LessonProgress] = []
    func progress() async throws -> [String: LessonProgress] {
        Dictionary(uniqueKeysWithValues: saved.map { ($0.lessonID, $0) })
    }
    func save(_ progress: LessonProgress) async throws {}
    func certificates() async throws -> [Certificate] { [] }
    func addCertificate(_ certificate: Certificate) async throws {}
}

private actor CellarStub: CellarRepository {
    private(set) var added: [String] = []
    func entries() async throws -> [CellarEntry] { [] }
    func update(_ wineKey: String, verdict: Verdict?, note: String?) async throws {}
    func delete(_ wineKey: String) async throws {}
    func save(_ draft: NewNoteDraft) async throws -> CellarEntry? { nil }
    func wineKeys() async throws -> Set<String> { Set(added) }
    func addWantToTry(_ wine: Wine) async throws { added.append(wine.id) }
    func tastedWineKeys() async throws -> Set<String> { [] }
    func addTasted(_ wine: Wine, verdict: Verdict) async throws {}
}

@MainActor
struct HomeViewModelTests {
    let day = Date(timeIntervalSince1970: 1_793_000_000)

    private func load(at date: Date, cellar: CellarStub = CellarStub(), learning: LearningStub = LearningStub()) async -> HomeViewModel {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Lisbon")!
        let viewModel = HomeFactory(profiles: ProfilesStub(), maps: MapStub(), catalog: CatalogStub(),
                                      cellar: cellar, courses: CoursesStub(), learning: learning, friends: FriendsRepositoryStub(),
                                      now: { date }, calendar: calendar)
            .makeViewModel(coordinator: HomeCoordinator(onOpenCourse: { _ in }, onOpenLearn: { _ in }))
        await viewModel.load()
        return viewModel
    }

    @Test func HOME_R02_greetsByFirstName() async {
        let cards = await load(at: day).uiModel.content?.cards
        #expect(cards?.first == .header(greeting: "Welcome back, Elisa", hasUnread: false))
    }

    @Test func HOME_R06_R09_daySuggestion_comesWithTheRecipe() async throws {
        let cards = try #require(await load(at: day).uiModel.content?.cards)
        guard case let .topMatch(wine) = cards.first(where: { $0.kind == "topMatch" }) else {
            Issue.record("no suggestion"); return
        }
        #expect(wine.dish?.title == "Lamb stew")
        #expect(wine.dish?.ingredients == ["800 g lamb"])
    }

    @Test func HOME_R07_aNoteThatMovesTheMap_theHeroFollows() async throws {
        let maps = MovingMapStub(map: HomeContentModel.full.palateMap)
        let viewModel = HomeFactory(profiles: ProfilesStub(), maps: maps, catalog: RankedCatalogStub(),
                                    cellar: CellarStub(), courses: CoursesStub(), learning: LearningStub(),
                                    friends: FriendsRepositoryStub())
            .makeViewModel(coordinator: HomeCoordinator(onOpenCourse: { _ in }, onOpenLearn: { _ in }))
        func hero() -> Wine? {
            guard case let .topMatch(wine) = viewModel.uiModel.content?.cards.first(where: { $0.kind == "topMatch" }) else { return nil }
            return wine
        }
        await viewModel.load()
        let before = try #require(hero())
        #expect(before.dish?.title == "Lamb stew")

        // A note on a wine the user loved pulls the map all the way to it (the stub saves the wine's own map); the
        // saved note reads the whole Home again.
        let loved = try #require(HomeContentModel.full.catalog.first { $0.type == "Red" && $0.id != before.id })
        try await maps.saveRatedMap(loved.profile, wineKey: loved.id, verdict: .yes, at: .now)
        await viewModel.reload()

        let after = try #require(hero())
        #expect(after.id == loved.id)
        #expect(after.dish?.title == "Lamb stew")
        #expect(viewModel.uiModel.content?.palateMap == loved.profile)
    }

    @Test func HOME_R12_aLessonOpened_showsContinueAtItsLesson() async throws {
        let learning = LearningStub(saved: [
            LessonProgress(lessonID: "grape-tannat-l01", courseID: "grape-tannat", currentStep: 5, completedAt: day,
                           lastOpenedAt: day, xp: 15),
            LessonProgress(lessonID: "grape-tannat-l02", courseID: "grape-tannat", currentStep: 2, lastOpenedAt: day)
        ])
        let cards = try #require(await load(at: day, learning: learning).uiModel.content?.cards)
        guard case let .continueLesson(course) = cards.first(where: { $0.kind == "continueLesson" }) else {
            Issue.record("no Continue card"); return
        }
        #expect(course.title == "Tannat")
        #expect(course.completedLessons == 1)
        #expect(course.current == LessonRef(number: 2, title: "Lesson 2", step: 3))
    }

    @Test func HOME_R11_noFriendsYet_showsTheInvite() async {
        let viewModel = await load(at: day)
        #expect(viewModel.uiModel.content?.cards.contains(.friends(.noFriends)) == true)
        #expect(viewModel.uiModel.inviteLink?.absoluteString == "https://uvva.app/invite/u1")
    }

    @Test func HOME_R19_wordOfTheDay_staysAllDay() async {
        let morning = await load(at: day).uiModel.content?.cards.first { $0.kind == "wordOfTheDay" }
        let evening = await load(at: day.addingTimeInterval(3 * 3600)).uiModel.content?.cards.first { $0.kind == "wordOfTheDay" }
        #expect(morning == evening)
    }

    // MARK: CELLAR-R01 · Add to cellar from the day's suggestion

    @Test func addToCellar_savesTheWineOnce_andMarksItSaved() async throws {
        let cellar = CellarStub()
        let viewModel = await load(at: day, cellar: cellar)
        let wine = try #require(HomeContentModel.full.catalog.first)

        await viewModel.addToCellar(wine)
        await viewModel.addToCellar(wine)

        #expect(viewModel.uiModel.cellarWineKeys.contains(wine.id))
        #expect(await cellar.added == [wine.id])
    }

    @Test func HOME_R11_friendsKeptOnTheDevice_fillTheCard() async throws {
        let marina = Friend(id: "m", name: "Marina", map: HomeContentModel.full.palateMap, addedAt: .now)
        let model = HomeFactory(profiles: ProfilesStub(), maps: MapStub(), catalog: CatalogStub(),
                                cellar: CellarStub(), courses: CoursesStub(), learning: LearningStub(),
                                friends: FriendsRepositoryStub(list: [marina]))
            .makeViewModel(coordinator: HomeCoordinator(onOpenCourse: { _ in }, onOpenLearn: { _ in }))
        try await model.prepare()
        #expect(model.uiModel.content?.cards.contains(.friends(.hasMatch(name: "Marina", compatibility: 100))) == true)
    }

    @Test func HOME_R11_cardWithFriends_opensTheFriendsTab() {
        var opened = false
        let model = HomeFactory(profiles: ProfilesStub(), maps: MapStub(), catalog: CatalogStub(),
                                cellar: CellarStub(), courses: CoursesStub(), learning: LearningStub(),
                                friends: FriendsRepositoryStub())
            .makeViewModel(coordinator: HomeCoordinator(onOpenCourse: { _ in }, onOpenLearn: { _ in },
                                                        onOpenFriends: { opened = true }))
        model.openFriends()
        #expect(opened)
    }

    @Test func HOME_R17_changedMapCard_opensTheMapHistory() {
        var opened = false
        let model = HomeFactory(profiles: ProfilesStub(), maps: MapStub(), catalog: CatalogStub(),
                                cellar: CellarStub(), courses: CoursesStub(), learning: LearningStub(),
                                friends: FriendsRepositoryStub())
            .makeViewModel(coordinator: HomeCoordinator(onOpenCourse: { _ in }, onOpenLearn: { _ in },
                                                        onOpenMapHistory: { opened = true }))
        model.openMapHistory()
        #expect(opened)
    }

    @Test func uiModel_publishesLoadingContentAndSavedWine() async throws {
        let model = HomeFactory(profiles: ProfilesStub(), maps: MapStub(), catalog: CatalogStub(),
                                 cellar: CellarStub(), courses: CoursesStub(), learning: LearningStub(),
                                 friends: FriendsRepositoryStub())
            .makeViewModel(coordinator: HomeCoordinator(onOpenCourse: { _ in }, onOpenLearn: { _ in }))
        var presentations: [HomeUIModel] = []
        let subscription = model.$uiModel.sink { presentations.append($0) }
        defer { subscription.cancel() }

        try await model.prepare()
        let wine = try #require(HomeContentModel.full.catalog.first)
        await model.addToCellar(wine)

        #expect(presentations.first?.isLoading == true)
        #expect(presentations.first?.content == nil)
        #expect(presentations.contains { !$0.isLoading && $0.content != nil })
        #expect(presentations.last?.cellarWineKeys.contains(wine.id) == true)
        #expect(presentations.last?.inviteLink?.absoluteString == "https://uvva.app/invite/u1")
    }

}

@MainActor
private struct FailingHomeLoader: LoadHomeUseCaseProtocol {
    struct Failure: Error {}
    func execute() async throws -> HomeLoadResultModel { throw Failure() }
}

@MainActor
private struct UnusedCellarAction: AddWineToCellarUseCaseProtocol {
    func execute(_ wine: Wine) async throws {}
}

@MainActor
struct HomePresentationTests {
    @Test func preparationFailureDoesNotPublishPartialState() async {
        let model = HomeViewModel(
            loadHomeUseCase: FailingHomeLoader(), loadPalateStateUseCase: PalateStateStub(), rankWinesUseCase: WineRankingSpy(),
            addWineToCellarUseCase: UnusedCellarAction(),
            coordinator: HomeCoordinator(onOpenCourse: { _ in }, onOpenLearn: { _ in }),
            now: Date.init, calendar: .current
        )
        do {
            try await model.prepare()
            Issue.record("Expected preparation to fail")
        } catch {
            #expect(error is FailingHomeLoader.Failure)
        }
        #expect(model.uiModel.content == nil)
        #expect(model.uiModel.inviteLink == nil)
        #expect(model.uiModel.cellarWineKeys.isEmpty)
    }

    @Test func navigationIsForwardedWithoutLoadingData() {
        var openedCourse: String?
        var openedKind: CourseKind?
        let model = HomeViewModel(
            loadHomeUseCase: FailingHomeLoader(), loadPalateStateUseCase: PalateStateStub(), rankWinesUseCase: WineRankingSpy(),
            addWineToCellarUseCase: UnusedCellarAction(),
            coordinator: HomeCoordinator(
                onOpenCourse: { openedCourse = $0 },
                onOpenLearn: { openedKind = $0 }
            ),
            now: Date.init, calendar: .current
        )
        model.openCourse("grape-tannat")
        model.openLearn(.grape)
        #expect(openedCourse == "grape-tannat")
        #expect(openedKind == .grape)
        #expect(model.uiModel.content == nil)
    }
}

private struct RegionFlowCatalog: CourseCatalog {
    let region = Course(id: "region-test", kind: .region, order: 1, title: "Test Region", about: "",
        countries: ["Portugal"], lessons: (1...6).map {
            LessonSummary(id: "region-test-l0\($0)", courseID: "region-test", order: $0,
                title: "Lesson \($0)", subtitle: "", xp: 15, minutes: 3, isReview: false, objectives: [])
        })
    func courses(_ kind: CourseKind) async throws -> [Course] { kind == .region ? [region] : [] }
    func course(id: String) async throws -> Course? { id == region.id ? region : nil }
    func lesson(id: String) async throws -> Lesson? {
        region.lessons.first { $0.id == id }.map {
            Lesson(summary: $0, steps: [.concept(title: "One", body: "Body", highlight: nil),
                .concept(title: "Two", body: "Body", highlight: nil), .summary(title: "Done", points: [])])
        }
    }
}

@MainActor
private final class HomeProgressRefresh {
    weak var home: HomeViewModel?
    func reload() { Task { await home?.load() } }
}

@MainActor
private final class SuspendedHomeSnapshot: LoadHomeUseCaseProtocol {
    let old: HomeLoadResultModel
    let latest: HomeLoadResultModel
    var pending: CheckedContinuation<HomeLoadResultModel, Never>?
    var calls = 0
    init(old: HomeLoadResultModel, latest: HomeLoadResultModel) { self.old = old; self.latest = latest }
    func execute() async throws -> HomeLoadResultModel {
        calls += 1
        if calls == 1 { return await withCheckedContinuation { pending = $0 } }
        return latest
    }
    func resume() { pending?.resume(returning: old); pending = nil }
}

@MainActor
struct ModuleStateFlowTests {
    private func waitUntil(_ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now.advanced(by: .seconds(5))
        while !condition(), ContinuousClock.now < deadline { try await Task.sleep(for: .milliseconds(5)) }
        try #require(condition())
    }

    @Test func regionCard_completeTwoLessons_leaveThird_homeAndEveryEntryResumeStatePlusOne() async throws {
        let container = try AppStore.makeInMemoryContainer()
        let store = LearningStore(modelContainer: container)
        let catalog = RegionFlowCatalog()
        let course = catalog.region
        let refresh = HomeProgressRefresh()
        let learn = LearnFactory(catalog: catalog, learning: store, profiles: ProfilesStub())
            .makeViewModel(onProgressChange: { refresh.reload() })
        let home = HomeFactory(profiles: ProfilesStub(), maps: MapStub(), catalog: CatalogStub(),
            cellar: CellarStub(), courses: catalog, learning: store, friends: FriendsRepositoryStub())
            .makeViewModel(coordinator: HomeCoordinator(
                onOpenCourse: { id in Task { await learn.openCourse(id: id) } }, onOpenLearn: { _ in },
                onOpenLesson: { suggestion in Task { await learn.openCourse(id: suggestion.courseID, lessonID: suggestion.lessonID) } }))
        refresh.home = home
        await home.load()
        guard case let .learnShortcuts(initial)? = home.uiModel.content?.cards.first(where: { $0.kind == "learnShortcuts" }) else {
            Issue.record("Missing A REGION"); return
        }
        let suggested = try #require(initial.first { $0.course.kind == .region })
        #expect(suggested.lesson.order == 1)
        home.openLesson(suggested)
        try await waitUntil { learn.player != nil && !learn.uiModel.isLoadingLesson }
        for number in 1...2 {
            let player = try #require(learn.player)
            #expect(player.lesson.summary.order == number)
            player.begin()
            player.primary()
            player.primary() // Summary persists completion immediately, without leaving.
            try await waitUntil { !learn.uiModel.isLoadingLesson }
            let snapshot = try await store.snapshot(for: [course])
            #expect(snapshot.modules[course.id]?.state == number)
            #expect(snapshot.lessons[player.lesson.id]?.isCompleted == true)
            player.primary()
            try await waitUntil { learn.player?.lesson.summary.order == number + 1 && !learn.uiModel.isLoadingLesson }
        }
        let third = try #require(learn.player)
        third.begin()
        third.primary()
        #expect(third.stepIndex == 1)
        third.close()
        try await waitUntil { learn.player == nil }
        try await waitUntil {
            home.uiModel.content?.cards.contains {
                if case let .continueLesson(card) = $0 { return card.current?.number == 3 && card.completedLessons == 2 }
                return false
            } == true
        }
        guard case let .continueLesson(card)? = home.uiModel.content?.cards.first(where: { $0.kind == "continueLesson" }) else {
            Issue.record("Missing Continue Lesson"); return
        }
        #expect(card.current?.number == 3)
        #expect(card.completedLessons == 2)
        #expect(card.totalLessons == 6)
        guard case let .learnShortcuts(updated)? = home.uiModel.content?.cards.first(where: { $0.kind == "learnShortcuts" }) else {
            Issue.record("Missing A REGION after progress"); return
        }
        let sameRegion = try #require(updated.first { $0.course.kind == .region })
        #expect(sameRegion.lesson.order == 3)
        home.openLesson(sameRegion)
        try await waitUntil { learn.player != nil && !learn.uiModel.isLoadingLesson }
        #expect(learn.player?.lesson.summary.order == 3)
        #expect(learn.player?.stepIndex == 1)
        learn.player?.close()
        try await waitUntil { learn.player == nil }
        home.openCourse(course.id)
        try await waitUntil { learn.player != nil && !learn.uiModel.isLoadingLesson }
        #expect(learn.player?.lesson.summary.order == 3)
        #expect(learn.player?.stepIndex == 1)
        let relaunched = LearnFactory(catalog: catalog, learning: LearningStore(modelContainer: container),
            profiles: ProfilesStub()).makeViewModel()
        await relaunched.openCourse(id: course.id)
        #expect(relaunched.player?.lesson.summary.order == 3)
        #expect(relaunched.player?.stepIndex == 1)
    }
    @Test func progressRefresh_duringAnOlderHomeLoad_doesNotReuseItsStaleState() async throws {
        let course = RegionFlowCatalog().region
        func content(_ state: Int) -> HomeLoadResultModel {
            var model = HomeContentModel.full
            model.courses = [CourseRules.summary(of: course,
                module: ModuleProgress(courseID: course.id, state: state, lastOpenedAt: Date()), progress: [:])]
            return HomeLoadResultModel(model: model, inviteLink: nil)
        }
        let source = SuspendedHomeSnapshot(old: content(1), latest: content(2))
        let home = HomeViewModel(loadHomeUseCase: source, loadPalateStateUseCase: PalateStateStub(), rankWinesUseCase: WineRankingSpy(),
            addWineToCellarUseCase: AddWineToCellarUseCase(cellar: CellarStub()),
            coordinator: HomeCoordinator(onOpenCourse: { _ in }, onOpenLearn: { _ in }),
            now: Date.init, calendar: .current)
        let oldLoad = Task { await home.load() }
        try await waitUntil { source.pending != nil }
        let refresh = Task { await home.load() }
        await Task.yield()
        source.resume()
        await oldLoad.value
        await refresh.value
        #expect(source.calls == 2)
        guard case let .continueLesson(card)? = home.uiModel.content?.cards.first(where: { $0.kind == "continueLesson" }) else {
            Issue.record("Missing refreshed state"); return
        }
        #expect(card.completedLessons == 2)
        #expect(card.current?.number == 3)
    }

}
