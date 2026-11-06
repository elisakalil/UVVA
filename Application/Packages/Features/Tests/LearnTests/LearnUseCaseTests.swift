import Combine
import Core
import Foundation
import Testing
@testable import Learn

private struct OfflineLearning: LearningRepository {
    func snapshot(for courses: [Course]) async throws -> LearningSnapshot { throw URLError(.notConnectedToInternet) }
    func save(_ progress: LessonProgress, in course: Course) async throws { try await save(progress) }

    func progress() async throws -> [String: LessonProgress] { throw URLError(.notConnectedToInternet) }
    func save(_ progress: LessonProgress) async throws { throw URLError(.notConnectedToInternet) }
    func certificates() async throws -> [Certificate] { throw URLError(.notConnectedToInternet) }
    func addCertificate(_ certificate: Certificate) async throws { throw URLError(.notConnectedToInternet) }
}

private struct OfflineCourses: CourseCatalog {
    func courses(_ kind: CourseKind) async throws -> [Course] { throw URLError(.notConnectedToInternet) }
    func course(id: String) async throws -> Course? { throw URLError(.notConnectedToInternet) }
    func lesson(id: String) async throws -> Lesson? { throw URLError(.notConnectedToInternet) }
}

@MainActor
struct LearnUseCaseTests {
    @Test func failedReload_preservesPreviouslyLoadedContent() async {
        let course = Fixture.course("grape-tannat")
        let certificate = Certificate(courseID: course.id, date: Fixture.day)
        let record = LessonProgress(lessonID: course.lessons[0].id, courseID: course.id,
                                    currentStep: 3, lastOpenedAt: Fixture.day)
        let previous = LearnContentModel(courses: [.grape: [course]], progress: [record.lessonID: record],
                                    certificates: [certificate], firstName: "Elisa")
        let result = await LoadLearnUseCase(catalog: OfflineCourses(), learning: OfflineLearning(),
                                            profiles: ProfilesStub()).execute(previous: previous)
        #expect(result.courses[.grape]?.map(\.id) == [course.id])
        #expect(result.progress[record.lessonID]?.currentStep == 3)
        #expect(result.certificates == [certificate])
        #expect(result.firstName == "Elisa")
    }

    @Test func failedAward_doesNotExposeAnUnpersistedCertificate() async {
        let course = Fixture.course("grape-tannat", lessons: 1)
        let record = LessonProgress(lessonID: course.lessons[0].id, courseID: course.id,
                                    currentStep: 5, completedAt: Fixture.day, lastOpenedAt: Fixture.day, xp: 15)
        let result = await CompleteCourseUseCase(learning: OfflineLearning(), now: { Fixture.day })
            .execute(course, previous: LearnContentModel(progress: [record.lessonID: record]))
        #expect(result.earned == nil)
        #expect(result.certificates.isEmpty)
        #expect(result.progress[record.lessonID]?.isCompleted == true)
    }

    @Test func missingLesson_doesNotReplaceTheCurrentPlayer() async {
        let course = Fixture.course("grape-tannat")
        let model = LearnFactory(catalog: CatalogStub(all: [course], lessons: Fixture.lessons(of: course)),
                                  learning: LearningSpy(), profiles: ProfilesStub()).makeViewModel()
        await model.openCourse(id: course.id)
        let current = try? #require(model.player)
        await model.openLesson(course, lessonID: "missing")
        #expect(model.players.count == 1)
        #expect(model.player === current)
    }
}

@MainActor
struct LearnPublicationTests {
    @Test func listUIModel_publishesQueryFiltersAndNavigation() async {
        let course = Fixture.course("grape-tannat")
        let model = LearnFactory(catalog: CatalogStub(all: [course], lessons: Fixture.lessons(of: course)),
                                  learning: LearningSpy(), profiles: ProfilesStub()).makeViewModel()
        var presentations: [LearnUIModel] = []
        let subscription = model.$uiModel.sink { presentations.append($0) }
        defer { subscription.cancel() }
        await model.load()
        model.updateQuery("tannat")
        #expect(presentations.last?.isSearching == true)
        #expect(presentations.last?.searchResults.first?.results.first?.title == course.title)
        await model.openCourse(id: course.id)
        #expect(presentations.last?.tab == .grape)
        #expect(presentations.last?.isPresentingPlayer == true)
    }

    @Test func playerUIModel_publishesStepSelectionAndFeedback() async throws {
        let course = Fixture.course("grape-tannat")
        let model = LearnFactory(catalog: CatalogStub(all: [course], lessons: Fixture.lessons(of: course)),
                                  learning: LearningSpy(), profiles: ProfilesStub()).makeViewModel()
        await model.openCourse(id: course.id)
        let player = try #require(model.player)
        var presentations: [LessonPlayerUIModel] = []
        let subscription = player.$uiModel.sink { presentations.append($0) }
        defer { subscription.cancel() }
        #expect(presentations.last?.isCover == true)
        player.begin()
        player.primary()
        player.primary()
        player.tapOption(2)
        player.primary()
        #expect(presentations.last?.stepIndex == 2)
        guard case let .feedback(feedback) = presentations.last?.footer else {
            Issue.record("Expected published feedback"); return
        }
        #expect(feedback.isCorrect)
    }
}
