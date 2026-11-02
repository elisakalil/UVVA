import Core
import DesignSystem
import Foundation
import Observation

/// The Learn tab (LEARN.md): three lists of courses, the lesson player they open, and the certificates.
/// Home and You open it through the app (APP-R06) with `show(_:)` and `openCourse(id:)`.
@MainActor @Observable
public final class LearnViewModel {
    /// LEARN-R03: Learn opens on By region.
    public var tab: CourseKind = .region
    private(set) var courses: [CourseKind: [Course]] = [:]
    private(set) var progress: [String: LessonProgress] = [:]
    private(set) var certificates: [Certificate] = []
    /// The one course open in each tab (LEARN-R06, R09).
    private(set) var openCourses: [CourseKind: String] = [:]
    private(set) var grapeFilter: GrapeFilter = .all
    /// Nil shows every level (LEARN-R10).
    private(set) var pathLevel: String?
    private(set) var country: String?
    /// The region last tapped on the map: it leads the list below the map.
    private(set) var pickedRegion: String?
    /// The lessons opened one from another, the one on screen last. Back from the first screen a lesson showed
    /// returns to the one before; from the first lesson's, it leaves.
    private(set) var players: [LessonPlayerViewModel] = []
    /// The lesson on screen, over the whole app.
    var player: LessonPlayerViewModel? { players.last }
    /// A certificate opened from its course ("View certificate").
    private(set) var sharedCertificate: CertificateUIModel?
    /// "Search modules"; while it has words, the results take the place of the tabs.
    var query = ""

    private var firstName = ""
    private let catalog: any CourseCatalog
    private let learning: any LearningRepository
    private let profiles: any ProfileRepository
    private let now: () -> Date
    private let pickToast: (Int) -> Int
    private let onProgressChange: () -> Void

    public init(catalog: any CourseCatalog, learning: any LearningRepository, profiles: any ProfileRepository,
                now: @escaping () -> Date = Date.init, pickToast: @escaping (Int) -> Int = { Int.random(in: 0..<$0) },
                onProgressChange: @escaping () -> Void = {}) {
        self.catalog = catalog
        self.learning = learning
        self.profiles = profiles
        self.now = now
        self.pickToast = pickToast
        self.onProgressChange = onProgressChange
    }

    /// Reads the courses, the progress and the certificates. Again after the content import ends.
    public func load() async {
        for kind in CourseKind.allCases {
            courses[kind] = (try? await catalog.courses(kind)) ?? courses[kind] ?? []
        }
        progress = (try? await learning.progress()) ?? progress
        certificates = (try? await learning.certificates()) ?? certificates
        firstName = ((try? await profiles.currentProfile()) ?? nil)?.firstName ?? firstName
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
        if course.kind == .grape, Self.grapes([course], filter: grapeFilter).isEmpty { grapeFilter = .all }
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

    /// The countries of By region, in the order of their first region.
    var countries: [String] {
        var seen: [String] = []
        for name in (courses[.region] ?? []).compactMap(\.countries.first) where !seen.contains(name) { seen.append(name) }
        return seen
    }

    // MARK: Lessons (LEARN-R11)

    /// The course button: lesson 1, the lesson to continue at its step, or lesson 1 to review.
    func start(_ course: Course) async {
        guard let entry = CourseRules.entry(for: course, progress: progress) else { return }
        await open(course, lessonID: entry.lessonID, step: entry.step)
    }

    /// One lesson, from the search: where it was left, or its cover.
    func openLesson(_ course: Course, lessonID: String) async {
        await open(course, lessonID: lessonID, step: progress[lessonID]?.currentStep)
    }

    func startCourse(id: String) async {
        guard let course = course(id: id) else { return }
        await start(course)
    }

    /// A completed lesson always opens on its cover, to be reviewed (LEARN-R19a).
    /// `stacking` opens it over the lesson on screen, so back returns there.
    private func open(_ course: Course, lessonID: String, step: Int?, stacking: Bool = false) async {
        guard let lesson = try? await catalog.lesson(id: lessonID) else { return }
        let saved = progress[lessonID]
        let isFirst = !stacking || players.isEmpty
        let opened = LessonPlayerViewModel(
            course: course, lesson: lesson, progress: saved, startStep: saved?.isCompleted == true ? nil : step,
            isFirst: isFirst, learning: learning, now: now, pickToast: pickToast,
            onCompleted: { [weak self] in await self?.lessonCompleted(in: course) },
            onExit: { [weak self] exit in self?.leave(course, exit) })
        players = isFirst ? [opened] : players + [opened]
    }

    private func leave(_ course: Course, _ exit: LessonPlayerViewModel.Exit) {
        let leaving = player
        Task {
            await leaving?.flush()
            progress = (try? await learning.progress()) ?? progress
            onProgressChange()
            switch exit {
            case .close:
                players = []
            case .back:
                guard let leaving, players.last === leaving else { return }
                players.removeLast()
                // Backs in a row carry over, so "Close" shows on the lesson before too.
                player?.backsInARow = leaving.backsInARow
            case let .open(lesson):
                await open(course, lessonID: lesson.id, step: progress[lesson.id]?.currentStep, stacking: true)
            }
        }
    }

    /// LEARN-R22: the lesson that finishes a course, in any position, earns its one certificate.
    private func lessonCompleted(in course: Course) async -> CertificateUIModel? {
        progress = (try? await learning.progress()) ?? progress
        defer { onProgressChange() }
        guard CourseRules.state(of: course, progress: progress) == .done,
              !certificates.contains(where: { $0.courseID == course.id }) else { return nil }
        let certificate = Certificate(courseID: course.id, date: now())
        do {
            try await learning.addCertificate(certificate)
        } catch {
            return nil
        }
        certificates = (try? await learning.certificates()) ?? certificates + [certificate]
        return await certificateModel(course, certificate)
    }

    // MARK: Certificates (LEARN-R23, R24)

    /// "View certificate" on a course, or a certificate in You › Certificates (YOU-R25).
    public func showCertificate(courseID: String) async {
        if !certificates.contains(where: { $0.courseID == courseID }) || course(id: courseID) == nil { await load() }
        guard let course = course(id: courseID),
              let certificate = certificates.first(where: { $0.courseID == courseID }) else { return }
        sharedCertificate = await certificateModel(course, certificate)
    }

    func closeCertificate() { sharedCertificate = nil }

    /// "What I can do now" is the review lesson's summary: the essentials of the whole course (LESSON-R10).
    private func certificateModel(_ course: Course, _ certificate: Certificate) async -> CertificateUIModel {
        var skills: [String] = []
        if let review = course.lessons.last(where: \.isReview) ?? course.lessons.last,
           let lesson = try? await catalog.lesson(id: review.id) {
            for case let .summary(_, points) in lesson.steps { skills = points }
            if skills.isEmpty { skills = review.objectives }
        }
        return Self.certificate(course: course, date: certificate.date, skills: skills, firstName: firstName)
    }

    static func certificate(course: Course, date: Date, skills: [String], firstName: String) -> CertificateUIModel {
        CertificateUIModel(
            date: date.formatted(.dateTime.day().month(.abbreviated).year()),
            kind: kindLabel(course.kind),
            lead: firstName.isEmpty ? String(localized: "Now I know", bundle: .module)
                : String(localized: "\(firstName) now knows", bundle: .module),
            title: course.title,
            about: course.about,
            skills: Array(skills.prefix(3)),
            xp: "+\(course.xp) XP",
            message: String(localized: "I just finished \(course.title) on UVVA.", bundle: .module)
        )
    }

    static func kindLabel(_ kind: CourseKind) -> String {
        switch kind {
        case .path: String(localized: "Module", bundle: .module)
        case .grape: String(localized: "Grape", bundle: .module)
        case .region: String(localized: "Region", bundle: .module)
        }
    }
}
