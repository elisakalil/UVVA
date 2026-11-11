import Core
import Foundation
import Match

@MainActor
struct LoadHomeUseCase: LoadHomeUseCaseProtocol {
    let profiles: any ProfileRepository
    let catalog: any CatalogRepository
    /// The map and what follows it: the part of the Home a rating changes, also read on its own (HOME-R10c).
    let loadPalateState: any LoadPalateStateUseCaseProtocol
    let rankWines: any RankWinesUseCaseProtocol
    let courses: any CourseCatalog
    let learning: any LearningRepository
    /// The friends kept on the device by the Friends tab (HOME-R11).
    let friends: any FriendsRepository

    func execute() async throws -> HomeLoadResultModel {
        let palate = try await loadPalateState.execute()
        let profile = try await profiles.currentProfile()
        let wines = try await rankWines.execute(for: palate.palateMap)
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
                firstName: profile?.firstName ?? "", palateMap: palate.palateMap, friends: friendList,
                courses: startedCourses, lastRating: palate.lastRating, ratedVerdicts: palate.ratedVerdicts,
                cellarWineKeys: palate.cellarWineKeys, catalog: wines,
                glossary: glossary, notifications: [], lessonCatalog: lessonCatalog, modules: snapshot.modules, lessonProgress: progress
            ),
            inviteLink: profile?.inviteLink
        )
    }
}
