import Core
import DesignSystem

@MainActor
protocol LearnCoordinatorProtocol: AnyObject {
    var players: [LessonPlayerViewModel] { get }
    var sharedCertificate: CertificateUIModel? { get }
    func open(_ course: Course, lessonID: String, step: Int?, stacking: Bool) async
    func showCertificate(_ course: Course, certificate: Certificate) async
    func closeCertificate()
}
