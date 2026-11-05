import Core
import Foundation
import Match

@MainActor
struct LoadHomeUseCase: LoadHomeUseCaseProtocol {
    let profiles: any ProfileRepository
    let maps: any PalateMapRepository
    let catalog: any CatalogRepository
    let cellar: any CellarRepository
    let courses: any CourseCatalog
    let learning: any LearningRepository
    let suggestionPool: Int
    let wineLimit: Int

    func execute() async throws -> LoadedHomeContent {
        guard let map = try await maps.currentMap() else {
            throw PreparationError.missingMap
        }

        let profile = try await profiles.currentProfile()
        let savedKeys = try await cellar.wineKeys()

        let wines = try await pairedWines(for: map)
        let glossary = try await catalog.glossary()
        let courses = await startedCourses()

        try Task.checkCancellation()

        return LoadedHomeContent(
            state: HomeState(
                firstName: profile?.firstName ?? "", palateMap: map, friends: [],
                courses: courses, lastRating: nil, ratedWineIDs: [], catalog: wines,
                glossary: glossary, notifications: []
            ),
            inviteLink: profile?.inviteLink,
            cellarWineKeys: savedKeys
        )
    }

    private func pairedWines(for map: PalateMap) async throws -> [Wine] {
        let wines = try await catalog.winesClosest(to: map, limit: wineLimit)
        let recipes = try await catalog.recipes()
        let pool = suggestionPool

        // Only Sendable values cross into the background task.
        return await Task.detached(priority: .userInitiated) {
            wines.enumerated().map { index, wine in
                guard index < pool,
                      let recipe = Pairing.recipe(for: wine, user: map, among: recipes)
                else { return wine }

                var result = wine
                result.dish = Pairing.dish(from: recipe)
                return result
            }
        }.value
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

}
