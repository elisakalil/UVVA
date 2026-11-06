import Core
import DesignSystem
import Foundation
import Combine

/// The Learn tab (LEARN.md): course lists, filters and search. Lesson flow belongs to the Coordinator.
/// Home and You open it through the app (APP-R06) with `show(_:)` and `openCourse(id:)`.
@MainActor
public final class LearnViewModel: LearnViewModelProtocol {
    @Published public private(set) var uiModel = LearnUIModel()
    private var subscriptions: Set<AnyCancellable> = []
    /// LEARN-R03: Learn opens on By region.
    public var tab: CourseKind = .region { didSet { refresh() } }
    var courses: [CourseKind: [Course]] { contentModel.courses }
    var progress: [String: LessonProgress] { contentModel.progress }
    var certificates: [Certificate] { contentModel.certificates }
    /// The one course open in each tab (LEARN-R06, R09).
    private(set) var openCourses: [CourseKind: String] = [:] { didSet { refresh() } }
    private(set) var grapeFilter: GrapeFilter = .all { didSet { refresh() } }
    /// Nil shows every level (LEARN-R10).
    private(set) var pathLevel: String? { didSet { refresh() } }
    private(set) var country: String? { didSet { refresh() } }
    /// The region last tapped on the map: it leads the list below the map.
    private(set) var pickedRegion: String? { didSet { refresh() } }
    var players: [LessonPlayerViewModel] { coordinator.players }
    public var player: LessonPlayerViewModel? { players.last }
    public var lessonLoadingPublisher: AnyPublisher<Bool, Never> {
        $uiModel.map(\.isLoadingLesson).removeDuplicates().eraseToAnyPublisher()
    }
    var sharedCertificate: CertificateUIModel? { coordinator.sharedCertificate }
    /// "Search modules"; while it has words, the results take the place of the tabs.
    var query = "" { didSet { refresh() } }

    private(set) var contentModel = LearnContentModel() { didSet { refresh() } }
    private let loadLearn: any LoadLearnUseCaseProtocol
    private let makeCoordinator: (LearnViewModel) -> any LearnCoordinatorProtocol
    private lazy var coordinator = makeCoordinator(self)

    init(loadLearn: any LoadLearnUseCaseProtocol,
         makeCoordinator: @escaping (LearnViewModel) -> any LearnCoordinatorProtocol) {
        self.loadLearn = loadLearn
        self.makeCoordinator = makeCoordinator
        coordinator.playersPublisher.sink { [weak self] players in
            guard let self else { return }
            self.uiModel.isPresentingPlayer = !players.isEmpty || self.uiModel.isLoadingLesson || self.uiModel.lessonError != nil
        }.store(in: &subscriptions)
        coordinator.loadingPublisher.sink { [weak self] loading in
            guard let self else { return }
            self.uiModel.isLoadingLesson = loading
            self.uiModel.isPresentingPlayer = loading || self.uiModel.lessonError != nil || self.player != nil
        }.store(in: &subscriptions)
        coordinator.errorPublisher.sink { [weak self] error in
            guard let self else { return }
            self.uiModel.lessonError = error
            self.uiModel.isPresentingPlayer = error != nil || self.uiModel.isLoadingLesson || self.player != nil
        }.store(in: &subscriptions)
        coordinator.certificatePublisher.sink { [weak self] certificate in
            self?.uiModel.sharedCertificate = certificate
        }.store(in: &subscriptions)
    }

    public func load() async {
        contentModel = await loadLearn.execute(previous: contentModel)
        if country == nil, let first = countries.first { selectCountry(first) }
    }

    /// LEARN-R04: the Home opens a tab directly.
    public func show(_ kind: CourseKind) { tab = kind }

    /// From the Home or You: the tab of the course, the course open, and its lesson on screen (LEARN-R11).
    public func openCourse(id: String, lessonID: String? = nil) async {
        coordinator.beginLoading()
        if courses.values.allSatisfy(\.isEmpty) { await load() }
        let catalog = courses
        let selection = await Task.detached(priority: .userInitiated) {
            catalog.values.lazy.flatMap({ $0 }).first(where: { $0.id == id })
        }.value
        guard let course = selection else { coordinator.cancelLoading(); return }
        // Publish the prepared selection on MainActor; no observable state crosses the detached task.
        query = ""
        grapeFilter = .all
        pathLevel = nil
        reveal(course)
        if course.kind == .region { pickedRegion = course.id }
        uiModel.focusedCourseID = course.id
        await coordinator.open(course, lessonID: lessonID, stacking: false)
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
    public func toggle(_ courseID: String) {
        openCourses[tab] = openCourses[tab] == courseID ? nil : courseID
    }

    func selectGrapeFilter(_ filter: GrapeFilter) { grapeFilter = filter }

    public func selectPathLevel(_ level: String?) { pathLevel = level }

    /// LEARN-R06: a country opens its first region.
    public func selectCountry(_ name: String) {
        country = name
        pickedRegion = nil
        openCourses[.region] = (courses[.region] ?? []).first { $0.countries.first == name }?.id
    }

    /// LEARN-R06: a region tapped on the map opens and moves to the top of the list; it stays open when tapped again.
    public func selectRegion(_ courseID: String) {
        openCourses[.region] = courseID
        pickedRegion = courseID
    }

    var countries: [String] { listBuilder.countries }

    // MARK: Lessons (LEARN-R11)

    /// The course button: lesson 1, the lesson to continue at its step, or lesson 1 to review.
    func start(_ course: Course) async {
        await coordinator.open(course, lessonID: nil, stacking: false)
    }

    /// One lesson, from the search: where it was left, or its cover.
    func openLesson(_ course: Course, lessonID: String) async {
        await coordinator.open(course, lessonID: lessonID, stacking: false)
    }

    public func startCourse(id: String) async {
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

    public func saveLessonOnBackground() async { await coordinator.saveOnBackground() }
    public func retryLesson() async { await coordinator.retry() }
    public func cancelLessonLoading() { coordinator.cancelLoading() }

    public func closeCertificate() { coordinator.closeCertificate() }

    func progressUpdated(_ snapshot: LearningSnapshot) {
        var model = contentModel
        model.progress = snapshot.lessons
        model.modules.merge(snapshot.modules) { _, updated in updated }
        contentModel = model
    }

    func courseCompleted(_ result: CourseCompletionResultModel) {
        var model = contentModel
        model.progress = result.progress
        model.certificates = result.certificates
        model.modules.merge(result.modules) { _, updated in updated }
        contentModel = model
    }

    public func updateQuery(_ query: String) { self.query = query }

    private func refresh(_ content: LearnContentModel? = nil) {
        let content = content ?? contentModel
        let lists = LearnListPresentationBuilder(courses: content.courses, progress: content.progress, modules: content.modules,
                                                 certificates: content.certificates, openCourses: openCourses,
                                                 grapeFilter: grapeFilter, pathLevel: pathLevel,
                                                 country: country, pickedRegion: pickedRegion)
        var model = uiModel
        model.tab = tab
        model.query = query
        model.isSearching = isSearching
        model.pathFilters = lists.pathFilters
        model.pathGroups = lists.pathGroups
        model.grapeFilters = lists.grapeFilters
        model.grapeGroups = lists.grapeGroups
        model.countryFilters = lists.countryFilters
        model.regionGroups = lists.regionGroups
        model.regionMap = lists.regionMap
        model.searchResults = LearnSearchPresentationBuilder(courses: content.courses, query: query).searchResults
        uiModel = model
    }
}
