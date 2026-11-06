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

    func execute() async throws -> HomeLoadResultModel {
        guard let map = try await maps.currentMap() else {
            throw PreparationError.missingMap
        }

        let profile = try await profiles.currentProfile()
        let savedKeys = try await cellar.wineKeys()

        let wines = try await pairedWines(for: map)
        let glossary = try await catalog.glossary()
        var lessonCatalog: [Course] = []
        for kind in [CourseKind.region, .grape, .path] {
            lessonCatalog += try await courses.courses(kind)
        }
        let snapshot = try await learning.snapshot(for: lessonCatalog)
        let progress = snapshot.lessons
        let startedCourses = lessonCatalog.filter { course in
            let module = snapshot.modules[course.id]
            return module?.lastOpenedAt != nil || (module?.state ?? 0) > 0
        }.map { CourseRules.summary(of: $0, module: snapshot.modules[$0.id], progress: progress) }

        try Task.checkCancellation()

        return HomeLoadResultModel(
            model: HomeContentModel(
                firstName: profile?.firstName ?? "", palateMap: map, friends: [],
                courses: startedCourses, lastRating: nil, ratedWineIDs: [], catalog: wines,
                glossary: glossary, notifications: [], lessonCatalog: lessonCatalog, modules: snapshot.modules, lessonProgress: progress
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

}
