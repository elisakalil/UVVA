import Core
import DesignSystem
import Foundation
import Observation

/// The Learn tab (LEARN.md): course lists, filters and search. Lesson flow belongs to the Coordinator.
/// Home and You open it through the app (APP-R06) with `show(_:)` and `openCourse(id:)`.
@MainActor @Observable
public final class LearnViewModel {
    /// LEARN-R03: Learn opens on By region.
    public var tab: CourseKind = .region
    var courses: [CourseKind: [Course]] { state.content.courses }
    var progress: [String: LessonProgress] { state.content.progress }
    var certificates: [Certificate] { state.content.certificates }
    /// The one course open in each tab (LEARN-R06, R09).
    private(set) var openCourses: [CourseKind: String] = [:]
    private(set) var grapeFilter: GrapeFilter = .all
    /// Nil shows every level (LEARN-R10).
    private(set) var pathLevel: String?
    private(set) var country: String?
    /// The region last tapped on the map: it leads the list below the map.
    private(set) var pickedRegion: String?
    var players: [LessonPlayerViewModel] { coordinator.players }
    var player: LessonPlayerViewModel? { players.last }
    var sharedCertificate: CertificateUIModel? { coordinator.sharedCertificate }
    /// "Search modules"; while it has words, the results take the place of the tabs.
    var query = ""

    private let state: LearnState
    private let loadLearn: any LoadLearnUseCaseProtocol
    private let coordinator: any LearnCoordinatorProtocol

    init(state: LearnState, loadLearn: any LoadLearnUseCaseProtocol, coordinator: any LearnCoordinatorProtocol) {
        self.state = state
        self.loadLearn = loadLearn
        self.coordinator = coordinator
    }

    public func load() async {
        state.content = await loadLearn.execute(previous: state.content)
        if country == nil, let first = countries.first { selectCountry(first) }
    }

    /// LEARN-R04: the Home opens a tab directly.
    public func show(_ kind: CourseKind) { tab = kind }

    /// From the Home or You: the tab of the course, the course open, and its lesson on screen (LEARN-R11).
    public func openCourse(id: String) async {
        if courses.values.allSatisfy(\.isEmpty) { await load() }
        guard let course = course(id: id) else { return }
        reveal(course)
        await start(course)
    }

    /// The course's tab, with the course open (and its country, in By region).
    func reveal(_ course: Course) {
        tab = course.kind
        openCourses[course.kind] = course.id
        if course.kind == .region, let name = course.countries.first { country = name }
        // A filter that would hide the course gives way, so its row is there to scroll to.
        if course.kind == .grape, LearnListPresentationBuilder.grapes([course], filter: grapeFilter).isEmpty { grapeFilter = .all }
        if course.kind == .path, let level = pathLevel, course.level != level { pathLevel = nil }
    }

    func course(id: String) -> Course? {
        courses.values.lazy.flatMap(\.self).first { $0.id == id }
    }

    // MARK: Lists

    /// Only one course open at a time; tapping the open one closes it.
    func toggle(_ courseID: String) {
        openCourses[tab] = openCourses[tab] == courseID ? nil : courseID
    }

    func selectGrapeFilter(_ filter: GrapeFilter) { grapeFilter = filter }

    func selectPathLevel(_ level: String?) { pathLevel = level }

    /// LEARN-R06: a country opens its first region.
    func selectCountry(_ name: String) {
        country = name
        pickedRegion = nil
        openCourses[.region] = (courses[.region] ?? []).first { $0.countries.first == name }?.id
    }

    /// LEARN-R06: a region tapped on the map opens and moves to the top of the list; it stays open when tapped again.
    func selectRegion(_ courseID: String) {
        openCourses[.region] = courseID
        pickedRegion = courseID
    }

    var countries: [String] { listBuilder.countries }

    // MARK: Lessons (LEARN-R11)

    /// The course button: lesson 1, the lesson to continue at its step, or lesson 1 to review.
    func start(_ course: Course) async {
        guard let entry = CourseRules.entry(for: course, progress: progress) else { return }
        await coordinator.open(course, lessonID: entry.lessonID, step: entry.step, stacking: false)
    }

    /// One lesson, from the search: where it was left, or its cover.
    func openLesson(_ course: Course, lessonID: String) async {
        await coordinator.open(course, lessonID: lessonID, step: progress[lessonID]?.currentStep, stacking: false)
    }

    func startCourse(id: String) async {
        guard let course = course(id: id) else { return }
        await start(course)
    }

    // MARK: Certificates (LEARN-R23, R24)

    /// "View certificate" on a course, or a certificate in You › Certificates (YOU-R25).
    public func showCertificate(courseID: String) async {
        if !certificates.contains(where: { $0.courseID == courseID }) || course(id: courseID) == nil { await load() }
        guard let course = course(id: courseID),
              let certificate = certificates.first(where: { $0.courseID == courseID }) else { return }
        await coordinator.showCertificate(course, certificate: certificate)
    }

    func closeCertificate() { coordinator.closeCertificate() }

}
