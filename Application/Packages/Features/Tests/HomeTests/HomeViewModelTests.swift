import Core
import Foundation
import Testing
@testable import Home

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
    func currentMap() async throws -> PalateMap? { HomeState.full.palateMap }
    func saveQuizMap(_ map: PalateMap, at date: Date) async throws {}
    func history() async throws -> [MapChange] { [] }
}

private struct CatalogStub: CatalogRepository {
    func winesClosest(to map: PalateMap, limit: Int) async throws -> [Wine] {
        Array(HomeState.full.catalog.map { var wine = $0; wine.dish = nil; return wine }.prefix(limit))
    }
    func recipes() async throws -> [Recipe] {
        [Recipe(id: "stew", title: "Lamb stew", why: "Weight for weight.", course: "main", wineTypes: ["Red"],
                profile: PalateMap([.body: 7]),
                ingredients: [RecipeIngredient(name: "lamb", quantity: 800, unit: "g", note: nil, role: "base")],
                steps: ["Brown the lamb."])]
    }
    func glossary() async throws -> [GlossaryTerm] { HomeState.full.glossary }
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
        let viewModel = HomeViewModel(profiles: ProfilesStub(), maps: MapStub(), catalog: CatalogStub(),
                                      cellar: cellar, courses: CoursesStub(), learning: learning, now: { date }, calendar: calendar)
        await viewModel.load()
        return viewModel
    }

    @Test func HOME_R02_greetsByFirstName() async {
        let cards = await load(at: day).model?.cards
        #expect(cards?.first == .header(greeting: "Welcome back, Elisa", hasUnread: false))
    }

    @Test func HOME_R06_R09_daySuggestion_comesWithTheRecipe() async throws {
        let cards = try #require(await load(at: day).model?.cards)
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
        let cards = try #require(await load(at: day, learning: learning).model?.cards)
        guard case let .continueLesson(course) = cards.first(where: { $0.kind == "continueLesson" }) else {
            Issue.record("no Continue card"); return
        }
        #expect(course.title == "Tannat")
        #expect(course.completedLessons == 1)
        #expect(course.current == LessonRef(number: 2, title: "Lesson 2", step: 3))
    }

    @Test func HOME_R11_noFriendsYet_showsTheInvite() async {
        let viewModel = await load(at: day)
        #expect(viewModel.model?.cards.contains(.friends(.invite)) == true)
        #expect(viewModel.inviteLink?.absoluteString == "https://uvva.app/invite/u1")
    }

    @Test func HOME_R19_wordOfTheDay_staysAllDay() async {
        let morning = await load(at: day).model?.cards.first { $0.kind == "wordOfTheDay" }
        let evening = await load(at: day.addingTimeInterval(3 * 3600)).model?.cards.first { $0.kind == "wordOfTheDay" }
        #expect(morning == evening)
    }

    // MARK: CELLAR-R01 · Add to cellar from the day's suggestion

    @Test func addToCellar_savesTheWineOnce_andMarksItSaved() async throws {
        let cellar = CellarStub()
        let viewModel = await load(at: day, cellar: cellar)
        let wine = try #require(HomeState.full.catalog.first)

        await viewModel.addToCellar(wine)
        await viewModel.addToCellar(wine)

        #expect(viewModel.cellarWineKeys.contains(wine.id))
        #expect(await cellar.added == [wine.id])
    }
}
