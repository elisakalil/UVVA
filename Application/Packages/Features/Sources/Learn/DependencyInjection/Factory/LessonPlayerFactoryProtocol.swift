import Core
import DesignSystem

@MainActor
protocol LessonPlayerFactoryProtocol {
    func make(course: Course, lesson: Lesson, progress: LessonProgress?, startStep: Int?, isFirst: Bool,
              onCompleted: @escaping () async -> CertificateUIModel?,
              onExit: @escaping (LessonPlayerViewModel.Exit) -> Void) -> LessonPlayerViewModel
}
