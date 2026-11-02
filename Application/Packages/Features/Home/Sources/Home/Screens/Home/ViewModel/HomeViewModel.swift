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

    /// Loads again whenever something it shows may have changed (a new map, the content import ending).
    public func load() async {
        guard let map = try? await maps.currentMap() else { return }
        let profile = try? await profiles.currentProfile()
        inviteLink = profile?.inviteLink
        cellarWineKeys = (try? await cellar.wineKeys()) ?? []
        let pool = HomeCardsBuilder.dailySuggestionPool
        let wines = (try? await catalog.winesClosest(to: map, limit: pool + HomeCardsBuilder.winesForPalateCount)) ?? []
        let recipes = (try? await catalog.recipes()) ?? []
        let glossary = (try? await catalog.glossary()) ?? []

        // HOME-R06: the wines the day's suggestion is drawn from carry the dish that pairs with them.
        let paired = wines.enumerated().map { index, wine in
            guard index < pool, let recipe = Pairing.recipe(for: wine, user: map, among: recipes) else { return wine }
            var withDish = wine
            withDish.dish = Pairing.dish(from: recipe)
            return withDish
        }
        let state = HomeState(firstName: profile?.firstName ?? "", palateMap: map, friends: [], courses: await startedCourses(),
                              lastRating: nil, ratedWineIDs: [], catalog: paired, glossary: glossary, notifications: [])
        let day = calendar.ordinality(of: .day, in: .era, for: now()) ?? 0
        // The word of the day stays the same all day (HOME-R19, decided 2026-10-31).
        let builder = HomeCardsBuilder(calendar: calendar, pickWordIndex: { count in day % count })
        model = HomeUIModel(cards: builder.build(from: state, now: now()), palateMap: map)
    }

    /// Every course with a lesson opened, for "Continue" (HOME-R12, R13).
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

    /// "Add to cellar" on the day's suggestion: the wine goes in as Want to try (CELLAR-R01).
    func addToCellar(_ wine: Wine) async {
        guard !cellarWineKeys.contains(wine.id) else { return }
        // Marked saved only once the store has it, so a failed save leaves the button to try again.
        guard (try? await cellar.addWantToTry(wine)) != nil else { return }
        cellarWineKeys.insert(wine.id)
    }

    var inviteMessage: String {
        String(localized: "Map your taste in wine with me on UVVA.", bundle: .module)
    }
}
