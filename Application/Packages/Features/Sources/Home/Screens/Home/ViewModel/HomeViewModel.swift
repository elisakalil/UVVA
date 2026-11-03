import Core
import Foundation
import Match
import Observation

/// Reads the stores and builds the Home cards (HOME.md). Friends, ratings and notifications come with
/// their features; until then the cards that depend on them take their empty variant.
@MainActor @Observable
public final class HomeViewModel {
    private(set) var model: HomeUIModel?
    private(set) var inviteLink: URL?
    /// The wines already in the Cellar, so the day's suggestion shows it is saved.
    private(set) var cellarWineKeys: Set<String> = []
    
    private var loadTask: Task<Void, Error>?

    private let profiles: any ProfileRepository
    private let maps: any PalateMapRepository
    private let catalog: any CatalogRepository
    private let cellar: any CellarRepository
    private let courses: any CourseCatalog
    private let learning: any LearningRepository
    private let now: () -> Date
    private let calendar: Calendar
    private let onOpenCourse: (String) -> Void
    private let onOpenLearn: (CourseKind) -> Void

    /// Learn opens through the app (APP-R06): a course from "Continue", a tab from the shortcuts (HOME-R18).
    public init(profiles: any ProfileRepository, maps: any PalateMapRepository, catalog: any CatalogRepository,
                cellar: any CellarRepository, courses: any CourseCatalog, learning: any LearningRepository,
                now: @escaping () -> Date = Date.init, calendar: Calendar = .current,
                onOpenCourse: @escaping (String) -> Void = { _ in }, onOpenLearn: @escaping (CourseKind) -> Void = { _ in }) {
        self.profiles = profiles
        self.maps = maps
        self.catalog = catalog
        self.cellar = cellar
        self.courses = courses
        self.learning = learning
        self.now = now
        self.calendar = calendar
        self.onOpenCourse = onOpenCourse
        self.onOpenLearn = onOpenLearn
    }
    
    public func loadIfNeeded() async {
        guard model == nil else { return }
        await load()
    }

    public func load() async {
        try? await prepare()
    }

    public func prepare() async throws {
        if let loadTask {
            try await loadTask.value
            try Task.checkCancellation()
            return
        }

        let task = Task { try await self.readHome() }
        loadTask = task
        defer { loadTask = nil }

        try await task.value
        try Task.checkCancellation()
    }

    private func readHome() async throws {
        guard let map = try await maps.currentMap() else {
            throw PreparationError.missingMap
        }

        let profile = try await profiles.currentProfile()
        let savedKeys = try await cellar.wineKeys()

        let pool = HomeCardsBuilder.dailySuggestionPool
        let wines = try await catalog.winesClosest(
            to: map,
            limit: pool + HomeCardsBuilder.winesForPalateCount
        )

        let recipes = try await catalog.recipes()
        let glossary = try await catalog.glossary()
        let courses = await startedCourses()

        // Captura apenas valores Sendable, sem capturar o view model.
        let paired = await Task.detached(priority: .userInitiated) {
            wines.enumerated().map { index, wine in
                guard index < pool,
                      let recipe = Pairing.recipe(
                        for: wine,
                        user: map,
                        among: recipes
                      )
                else { return wine }

                var result = wine
                result.dish = Pairing.dish(from: recipe)
                return result
            }
        }.value

        try Task.checkCancellation()

        let date = now()
        let state = HomeState(
            firstName: profile?.firstName ?? "",
            palateMap: map,
            friends: [],
            courses: courses,
            lastRating: nil,
            ratedWineIDs: [],
            catalog: paired,
            glossary: glossary,
            notifications: []
        )

        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        let builder = HomeCardsBuilder(
            calendar: calendar,
            pickWordIndex: { count in day % count }
        )

        inviteLink = profile?.inviteLink
        cellarWineKeys = savedKeys
        model = HomeUIModel(
            cards: builder.build(from: state, now: date),
            palateMap: map
        )
    }

    private enum PreparationError: LocalizedError {
        case missingMap

        var errorDescription: String? {
            "Your palate map could not be loaded."
        }
    }

    private func startedCourses() async -> [CourseProgress] {
        let progress = (try? await learning.progress()) ?? [:]
        let started = Set(progress.values.map(\.courseID))
        var result: [CourseProgress] = []
        for kind in Set(started.compactMap(CourseKind.init(courseID:))) {
            for course in (try? await courses.courses(kind)) ?? [] where started.contains(course.id) {
                result.append(CourseRules.summary(of: course, progress: progress))
            }
        }
        return result
    }

    func openCourse(_ id: String) { onOpenCourse(id) }

    func openLearn(_ kind: CourseKind) { onOpenLearn(kind) }

    func addToCellar(_ wine: Wine) async {
        guard !cellarWineKeys.contains(wine.id) else { return }
        guard (try? await cellar.addWantToTry(wine)) != nil else { return }
        cellarWineKeys.insert(wine.id)
    }

    var inviteMessage: String {
        String(localized: "Map your taste in wine with me on UVVA.", bundle: .module)
    }
}
