import Core
import Foundation

@MainActor
struct LoadYouUseCase: LoadYouUseCaseProtocol {
    let profiles: any ProfileRepository
    let maps: any PalateMapRepository
    let catalog: any CatalogRepository
    let courses: any CourseCatalog
    let learning: any LearningRepository
    let reminders: any ReminderRepository

    func execute(previous: YouContentModel) async -> YouContentModel {
        async let profile = try? profiles.currentProfile()
        async let map = try? maps.currentMap()
        async let history = try? maps.history()
        async let reminder = try? reminders.reminder()
        async let learningContent = loadLearning(previous: previous)

        var content = await learningContent
        content.profile = await profile
        content.map = await map
        content.history = await history ?? []
        content.reminder = await reminder
        return content
    }

    private func loadLearning(previous: YouContentModel) async -> YouContentModel {
        async let activityRead = try? learning.activity()
        async let firstModule = try? catalog.firstPathModule()
        async let path = try? courses.courses(.path)
        async let grapes = try? courses.courses(.grape)
        async let regions = try? courses.courses(.region)

        let (activity, intro, pathCourses, grapeCourses, regionCourses) = await (activityRead, firstModule, path, grapes, regions)
        var content = previous
        guard !Task.isCancelled else { return content }
        let allCourses = (pathCourses ?? []) + (grapeCourses ?? []) + (regionCourses ?? [])
        if let regionCourses { content.regionCatalog = regionCourses }

        if let activity {
            content.lessons = activity.lessons
            content.certificates = activity.certificates
            let byID = Dictionary(allCourses.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            for certificate in activity.certificates {
                guard !Task.isCancelled else { return content }
                let id = certificate.courseID
                if let course = byID[id] {
                    content.certificateCourses[id] = course
                } else if content.certificateCourses[id] == nil {
                    content.certificateCourses[id] = try? await courses.course(id: id)
                }
            }

            let policy = CourseRecommendationPolicy()
            let completed = policy.completionDates(courses: allCourses, activity: activity)
            if let intro, pathCourses != nil,
               completed[intro.id] == nil || (grapeCourses != nil && regionCourses != nil) {
                content.recommendation = policy.select(intro: intro, courses: allCourses, activity: activity)
                content.recommendationStatus = .ready
                return content
            }

            // A partial catalog read must not replace an eligible recommendation with a guess.
            if let cached = content.recommendation,
               completed[cached.course.id] == nil,
               cached.reason == .introduction || (!activity.startedModuleIDs.contains(cached.course.id)
                   && !activity.lessons.values.contains { $0.courseID == cached.course.id }) {
                return content
            }
            content.recommendation = nil
        }
        content.recommendationStatus = .unavailable
        return content
    }
}
