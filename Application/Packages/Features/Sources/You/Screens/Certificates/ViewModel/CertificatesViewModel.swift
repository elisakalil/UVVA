import Combine

@MainActor
public final class CertificatesViewModel: CertificatesViewModelProtocol {
    @Published public private(set) var uiModel = CertificatesUIModel()
    private var subscription: AnyCancellable?
    private let state: YouState
    private let coordinator: any YouCoordinatorProtocol

    init(state: YouState, coordinator: any YouCoordinatorProtocol) {
        self.state = state
        self.coordinator = coordinator
        subscription = state.$content.sink { [weak self] content in
            self?.uiModel.rows = CertificatesPresentationBuilder().build(from: content)
        }
    }

    public func open(_ id: String) { coordinator.openCertificate(id) }
    public func startLearning() { coordinator.openLearn() }
}
