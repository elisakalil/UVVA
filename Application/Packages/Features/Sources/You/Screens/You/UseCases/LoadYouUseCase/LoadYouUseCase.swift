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
        var content = YouContentModel()
        content.profile = try? await profiles.currentProfile()
        content.map = (try? await maps.currentMap()) ?? nil
        content.history = (try? await maps.history()) ?? []
        content.reminder = (try? await reminders.reminder()) ?? nil
        content.firstModule = (try? await catalog.firstPathModule()) ?? nil
        content.lessons = (try? await learning.progress()) ?? previous.lessons
        content.certificates = (try? await learning.certificates()) ?? previous.certificates
        content.certificateCourses = await certificateCourses(for: content.certificates, cached: previous.certificateCourses)
        return content
    }

    private func certificateCourses(for certificates: [Certificate], cached: [String: Course]) async -> [String: Course] {
        var result = cached
        for certificate in certificates where result[certificate.courseID] == nil {
            result[certificate.courseID] = try? await courses.course(id: certificate.courseID)
        }
        return result
    }
}
