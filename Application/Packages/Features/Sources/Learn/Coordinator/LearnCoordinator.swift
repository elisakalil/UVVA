import Core
import DesignSystem
import Combine

/// Owns the lesson stack and certificate destinations. List selection stays in the screen ViewModel.
@MainActor
final class LearnCoordinator: LearnCoordinatorProtocol {
    @Published private(set) var players: [LessonPlayerViewModel] = []
    @Published private(set) var sharedCertificate: CertificateUIModel?
    var playersPublisher: AnyPublisher<[LessonPlayerViewModel], Never> { $players.eraseToAnyPublisher() }
    var certificatePublisher: AnyPublisher<CertificateUIModel?, Never> { $sharedCertificate.eraseToAnyPublisher() }
    @Published private(set) var isLoading = false
    @Published private(set) var loadError: String?
    var loadingPublisher: AnyPublisher<Bool, Never> { $isLoading.eraseToAnyPublisher() }
    var errorPublisher: AnyPublisher<String?, Never> { $loadError.eraseToAnyPublisher() }
    private var retryAction: (() async -> Void)?
    private var isLeaving = false
    private var isNavigating = false
    private var pendingClose: Task<Void, Never>?
    private var openGeneration = 0
    private let readModel: () -> LearnContentModel
    private let onProgressUpdated: (LearningSnapshot) -> Void
    private let onCourseCompleted: (CourseCompletionResultModel) -> Void
    private let playerFactory: any LessonPlayerFactoryProtocol
    private let loadLesson: any LoadLessonUseCaseProtocol
    private let refreshProgress: any RefreshProgressUseCaseProtocol
    private let completeCourse: any CompleteCourseUseCaseProtocol
    private let loadSkills: any LoadCertificateSkillsUseCaseProtocol
    private let onProgressChange: () -> Void

    init(readModel: @escaping () -> LearnContentModel,
         onProgressUpdated: @escaping (LearningSnapshot) -> Void,
         onCourseCompleted: @escaping (CourseCompletionResultModel) -> Void,
         playerFactory: any LessonPlayerFactoryProtocol,
         loadLesson: any LoadLessonUseCaseProtocol, refreshProgress: any RefreshProgressUseCaseProtocol,
         completeCourse: any CompleteCourseUseCaseProtocol, loadSkills: any LoadCertificateSkillsUseCaseProtocol,
         onProgressChange: @escaping () -> Void) {
        self.readModel = readModel
        self.onProgressUpdated = onProgressUpdated
        self.onCourseCompleted = onCourseCompleted
        self.playerFactory = playerFactory
        self.loadLesson = loadLesson
        self.refreshProgress = refreshProgress
        self.completeCourse = completeCourse
        self.loadSkills = loadSkills
        self.onProgressChange = onProgressChange
    }

    func beginLoading() {
        isLoading = true
        loadError = nil
    }

    func retry() async { await retryAction?() }

    func saveOnBackground() async {
        guard let player = players.last else { return }
        leave(player.course, .checkpoint)
        await pendingClose?.value
    }

    func cancelLoading() {
        // An unsaved player stays available if saving failed.
        openGeneration += 1
        isLoading = false
        loadError = nil
        retryAction = nil
    }

    func open(_ course: Course, lessonID: String?, stacking: Bool) async {
        await open(course, lessonID: lessonID, stacking: stacking, showsLoading: true)
    }

    private func open(_ course: Course, lessonID: String?, stacking: Bool, showsLoading: Bool) async {
        openGeneration += 1
        let generation = openGeneration
        if showsLoading { beginLoading() }
        await pendingClose?.value
        guard generation == openGeneration else { return }
        // A failed exit may not be bypassed by opening another player.
        guard !isLeaving, loadError == nil else { return }
        do {
            if !stacking, let current = players.last { try await persistDeparture(of: current) }
            guard generation == openGeneration else { return }
            let refreshed = try await refreshProgress.execute([course])
            guard lessonID == nil || course.lessons.contains(where: { $0.id == lessonID }) else {
                throw LessonLoadError.unavailable
            }
            let module = refreshed.modules[course.id]
            // Only an explicitly completed lesson is reviewable. Every unfinished entry uses state + 1.
            let requestedReview = lessonID.flatMap { requested in
                course.lessons.prefix(module?.state ?? 0).first { $0.id == requested }?.id
            }
            let resolvedID = requestedReview ?? CourseRules.entry(for: course, module: module, progress: refreshed.lessons)?.lessonID
                ?? (module?.state == course.lessons.count ? course.lessons.first?.id : nil)
            guard let resolvedID, let lesson = await loadLesson.execute(id: resolvedID) else {
                throw LessonLoadError.unavailable
            }
            guard generation == openGeneration else { return }
            guard !Task.isCancelled else { cancelLoading(); return }
            let saved = refreshed.lessons[resolvedID]
            let isFirst = !stacking || players.isEmpty
            let player = playerFactory.make(
                course: course, lesson: lesson, progress: saved,
                isFirst: isFirst,
                onCompleted: { [weak self] in await self?.lessonCompleted(in: course) },
                onExit: { [weak self] exit in self?.leave(course, exit) }
            )
            onProgressUpdated(refreshed)
            players = isFirst ? [player] : players + [player]
            isLoading = false
            retryAction = nil
            player.savePendingCompletion()
        } catch {
            guard generation == openGeneration else { return }
            loadError = String(localized: "Couldn't load the lesson. Please try again.", bundle: .module)
            isLoading = false
            retryAction = { [weak self] in await self?.open(course, lessonID: lessonID, stacking: stacking) }
        }
    }

    private enum LessonLoadError: Error { case unavailable }

    /// Every exit (Back, drag, close, next lesson, certificate) passes through this one save barrier.
    private func leave(_ course: Course, _ exit: LessonPlayerViewModel.Exit) {
        guard !isLeaving, !isNavigating, let leaving = players.last else { return }
        if leaving.hasSavedSummary {
            let destination = exit == .finish ? leaving.finishAfterSaving() : exit
            guard let destination else { return }
            isNavigating = true
            Task {
                defer { isNavigating = false }
                // Keep the Summary visible while reading the next lesson, without another saving screen.
                await applySavedExit(destination, in: course, showsLoading: false)
            }
            return
        }
        isLeaving = true
        openGeneration += 1
        beginLoading()
        pendingClose = Task {
            do {
                try await persistDeparture(of: leaving)
                guard players.last === leaving else { isLeaving = false; isLoading = false; return }
                isLeaving = false
                isLoading = false
                retryAction = nil
                // Clear before opening the next lesson: it must not wait on this task itself.
                pendingClose = nil
                let destination = exit == .finish ? leaving.finishAfterSaving() : exit
                if let destination { await applySavedExit(destination, in: course) }
            } catch {
                isLeaving = false
                loadError = String(localized: "Couldn't save your lesson. Please try again before leaving.", bundle: .module)
                isLoading = false
                pendingClose = nil
                retryAction = { [weak self] in self?.leave(course, exit) }
            }
        }
    }

    private func applySavedExit(_ exit: LessonPlayerViewModel.Exit, in course: Course, showsLoading: Bool = true) async {
        switch exit {
        case .close: players = []
        case .back:
            players.removeLast()
            // A stacked parent also comes from a fresh read, never its previous in-memory cursor.
            if let parent = players.last {
                let lessonID = parent.lesson.id
                players.removeLast()
                await open(course, lessonID: lessonID, stacking: !players.isEmpty, showsLoading: showsLoading)
            }
        case let .open(lesson):
            await open(course, lessonID: lesson.id, stacking: true, showsLoading: showsLoading)
        case .checkpoint, .finish: break
        }
    }

    private func persistDeparture(of player: LessonPlayerViewModel) async throws {
        try await player.saveOnExit()
        onProgressUpdated(try await refreshProgress.execute([player.course]))
        onProgressChange()
    }

    private func lessonCompleted(in course: Course) async -> CertificateUIModel? {
        let result = await completeCourse.execute(course, previous: readModel())
        onCourseCompleted(result)
        defer { onProgressChange() }
        guard let certificate = result.earned else { return nil }
        return await certificateModel(course, certificate)
    }

    func showCertificate(_ course: Course, certificate: Certificate) async {
        sharedCertificate = await certificateModel(course, certificate)
    }

    func closeCertificate() { sharedCertificate = nil }

    private func certificateModel(_ course: Course, _ certificate: Certificate) async -> CertificateUIModel {
        let skills = await loadSkills.execute(course)
        return CertificatePresentationBuilder.certificate(course: course, date: certificate.date,
                                                          skills: skills, firstName: readModel().firstName)
    }
}
