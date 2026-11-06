import Core
import Foundation

@MainActor
public struct LearnFactory: LearnFactoryProtocol {
    private let catalog: any CourseCatalog
    private let learning: any LearningRepository
    private let profiles: any ProfileRepository
    private let now: () -> Date
    private let pickToast: (Int) -> Int

    public init(catalog: any CourseCatalog, learning: any LearningRepository, profiles: any ProfileRepository,
                now: @escaping () -> Date = Date.init,
                pickToast: @escaping (Int) -> Int = { Int.random(in: 0..<$0) }) {
        self.catalog = catalog
        self.learning = learning
        self.profiles = profiles
        self.now = now
        self.pickToast = pickToast
    }

    public func makeViewModel(onProgressChange: @escaping () -> Void = {}) -> LearnViewModel {
        LearnViewModel(
            loadLearn: LoadLearnUseCase(catalog: catalog, learning: learning, profiles: profiles),
            makeCoordinator: { owner in
                LearnCoordinator(
                    readModel: { [weak owner] in owner?.contentModel ?? LearnContentModel() },
                    onProgressUpdated: { [weak owner] in owner?.progressUpdated($0) },
                    onCourseCompleted: { [weak owner] in owner?.courseCompleted($0) },
                    playerFactory: LessonPlayerFactory(saveProgress: SaveLessonProgressUseCase(learning: learning),
                                                        now: now, pickToast: pickToast),
                    loadLesson: LoadLessonUseCase(catalog: catalog),
                    refreshProgress: RefreshProgressUseCase(learning: learning),
                    completeCourse: CompleteCourseUseCase(learning: learning, now: now),
                    loadSkills: LoadCertificateSkillsUseCase(catalog: catalog), onProgressChange: onProgressChange
                )
            }
        )
    }
}
