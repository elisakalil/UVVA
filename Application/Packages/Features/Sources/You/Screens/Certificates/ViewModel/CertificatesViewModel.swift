import Observation

@MainActor @Observable
final class CertificatesViewModel {
    private let state: YouState
    private let coordinator: any YouCoordinatorProtocol

    init(state: YouState, coordinator: any YouCoordinatorProtocol) {
        self.state = state
        self.coordinator = coordinator
    }

    var rows: [CertificateRowUIModel] { CertificatesPresentationBuilder().build(from: state.content) }
    func open(_ id: String) { coordinator.openCertificate(id) }
    func startLearning() { coordinator.openLearn() }
}
