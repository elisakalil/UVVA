import Core
import DesignSystem
import Observation

/// Owns the lesson stack and certificate destinations. List selection stays in the screen ViewModel.
@MainActor @Observable
final class LearnCoordinator: LearnCoordinatorProtocol {
    private(set) var players: [LessonPlayerViewModel] = []
    private(set) var sharedCertificate: CertificateUIModel?
    private let state: LearnState
    private let playerFactory: any LessonPlayerFactoryProtocol
    private let loadLesson: any LoadLessonUseCaseProtocol
    private let refreshProgress: any RefreshProgressUseCaseProtocol
    private let completeCourse: any CompleteCourseUseCaseProtocol
    private let loadSkills: any LoadCertificateSkillsUseCaseProtocol
    private let onProgressChange: () -> Void

    init(state: LearnState, playerFactory: any LessonPlayerFactoryProtocol,
         loadLesson: any LoadLessonUseCaseProtocol, refreshProgress: any RefreshProgressUseCaseProtocol,
         completeCourse: any CompleteCourseUseCaseProtocol, loadSkills: any LoadCertificateSkillsUseCaseProtocol,
         onProgressChange: @escaping () -> Void) {
        self.state = state
        self.playerFactory = playerFactory
        self.loadLesson = loadLesson
        self.refreshProgress = refreshProgress
        self.completeCourse = completeCourse
        self.loadSkills = loadSkills
        self.onProgressChange = onProgressChange
    }

    func open(_ course: Course, lessonID: String, step: Int?, stacking: Bool) async {
        guard let lesson = await loadLesson.execute(id: lessonID) else { return }
        let saved = state.content.progress[lessonID]
        let isFirst = !stacking || players.isEmpty
        let player = playerFactory.make(
            course: course, lesson: lesson, progress: saved, startStep: saved?.isCompleted == true ? nil : step,
            isFirst: isFirst,
            onCompleted: { [weak self] in await self?.lessonCompleted(in: course) },
            onExit: { [weak self] exit in self?.leave(course, exit) }
        )
        players = isFirst ? [player] : players + [player]
    }

    private func leave(_ course: Course, _ exit: LessonPlayerViewModel.Exit) {
        let leaving = players.last
        Task {
            await leaving?.flush()
            state.content.progress = await refreshProgress.execute(previous: state.content.progress)
            onProgressChange()
            await apply(exit, from: leaving, in: course)
        }
    }

    private func apply(_ exit: LessonPlayerViewModel.Exit, from leaving: LessonPlayerViewModel?, in course: Course) async {
        switch exit {
        case .close:
            players = []
        case .back:
            guard let leaving, players.last === leaving else { return }
            players.removeLast()
        case let .open(lesson):
            await open(course, lessonID: lesson.id, step: state.content.progress[lesson.id]?.currentStep, stacking: true)
        }
    }

    private func lessonCompleted(in course: Course) async -> CertificateUIModel? {
        let result = await completeCourse.execute(course, previous: state.content)
        state.content.progress = result.progress
        state.content.certificates = result.certificates
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
                                                          skills: skills, firstName: state.content.firstName)
    }
}
