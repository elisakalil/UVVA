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
    /// The friends kept on the device by the Friends tab (HOME-R11).
    let friends: any FriendsRepository
    let suggestionPool: Int

    func execute() async throws -> HomeLoadResultModel {
        guard let map = try await maps.currentMap() else {
            throw PreparationError.missingMap
        }

        let profile = try await profiles.currentProfile()
        let savedKeys = try await cellar.wineKeys()
        // HOME-R23 and the changed-map card (HOME-R15): the wines rated so far and the last rating's moves.
        let history = try await maps.history()
        let ratedKeys = try await cellar.tastedWineKeys().union(Rating.wineKeys(in: history))
        let lastRating = Rating.last(in: history)

        let wines = try await pairedWines(for: map)
        let glossary = try await catalog.glossary()
        let friendList = (try? await friends.friends()) ?? []
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
                firstName: profile?.firstName ?? "", palateMap: map, friends: friendList,
                courses: startedCourses, lastRating: lastRating, ratedWineIDs: ratedKeys, catalog: wines,
                glossary: glossary, notifications: [], lessonCatalog: lessonCatalog, modules: snapshot.modules, lessonProgress: progress
            ),
            inviteLink: profile?.inviteLink,
            cellarWineKeys: savedKeys
        )
    }

    private func pairedWines(for map: PalateMap) async throws -> [Wine] {
        // An axis match can sit anywhere in the overall similarity ranking.
        let wines = try await catalog.winesClosest(to: map, limit: .max)
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
