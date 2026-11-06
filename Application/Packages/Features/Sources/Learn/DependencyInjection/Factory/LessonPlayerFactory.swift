import Core
import DesignSystem
import Foundation

@MainActor
struct LessonPlayerFactory: LessonPlayerFactoryProtocol {
    let saveProgress: any SaveLessonProgressUseCaseProtocol
    let now: () -> Date
    let pickToast: (Int) -> Int

    func make(course: Course, lesson: Lesson, progress: LessonProgress?, isFirst: Bool,
              onCompleted: @escaping () async -> CertificateUIModel?,
              onExit: @escaping (LessonPlayerViewModel.Exit) -> Void) -> LessonPlayerViewModel {
        LessonPlayerViewModel(course: course, lesson: lesson, progress: progress,
                             isFirst: isFirst, saveProgressUseCase: saveProgress, now: now,
                             pickToast: pickToast, onCompleted: onCompleted, onExit: onExit)
    }
}
