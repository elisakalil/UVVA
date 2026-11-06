import Combine
import Core
import Foundation
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
    func wineKeys() async throws -> Set<String> { Set(added) }
    func addWantToTry(_ wine: Wine) async throws { added.append(wine.id) }
}

@MainActor
struct HomeViewModelTests {
    let day = Date(timeIntervalSince1970: 1_793_000_000)

    private func load(at date: Date, cellar: CellarStub = CellarStub(), learning: LearningStub = LearningStub()) async -> HomeViewModel {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Lisbon")!
        let viewModel = HomeFactory(profiles: ProfilesStub(), maps: MapStub(), catalog: CatalogStub(),
                                      cellar: cellar, courses: CoursesStub(), learning: learning, now: { date }, calendar: calendar)
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
        guard case let .dailySuggestion(wine) = cards.first(where: { $0.kind == "dailySuggestion" }) else {
            Issue.record("no suggestion"); return
        }
        #expect(wine.dish?.title == "Lamb stew")
        #expect(wine.dish?.ingredients == ["800 g lamb"])
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

    @Test func uiModel_publishesLoadingContentAndSavedWine() async throws {
        let model = HomeFactory(profiles: ProfilesStub(), maps: MapStub(), catalog: CatalogStub(),
                                 cellar: CellarStub(), courses: CoursesStub(), learning: LearningStub())
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
            loadHomeUseCase: FailingHomeLoader(),
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
            loadHomeUseCase: FailingHomeLoader(),
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
            cellar: CellarStub(), courses: catalog, learning: store)
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
            return HomeLoadResultModel(model: model, inviteLink: nil, cellarWineKeys: [])
        }
        let source = SuspendedHomeSnapshot(old: content(1), latest: content(2))
        let home = HomeViewModel(loadHomeUseCase: source,
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
