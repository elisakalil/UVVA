import Combine
import Core
import DesignSystem

@MainActor
protocol LearnCoordinatorProtocol: AnyObject {
    var players: [LessonPlayerViewModel] { get }
    var sharedCertificate: CertificateUIModel? { get }
    var playersPublisher: AnyPublisher<[LessonPlayerViewModel], Never> { get }
    var certificatePublisher: AnyPublisher<CertificateUIModel?, Never> { get }
    var loadingPublisher: AnyPublisher<Bool, Never> { get }
    var errorPublisher: AnyPublisher<String?, Never> { get }
    func beginLoading()
    func saveOnBackground() async
    func retry() async
    func cancelLoading()
    func open(_ course: Course, lessonID: String?, stacking: Bool) async
    func showCertificate(_ course: Course, certificate: Certificate) async
    func closeCertificate()
}
