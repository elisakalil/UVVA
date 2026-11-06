import Combine

@MainActor
public final class CertificatesViewModel: CertificatesViewModelProtocol {
    @Published public private(set) var uiModel = CertificatesUIModel()
    private let readModel: () -> YouContentModel
    private let coordinator: any YouCoordinatorProtocol

    init(readModel: @escaping () -> YouContentModel, coordinator: any YouCoordinatorProtocol) {
        self.readModel = readModel
        self.coordinator = coordinator
        present(readModel())
    }

    func present(_ model: YouContentModel) {
        uiModel.rows = CertificatesPresentationBuilder().build(from: model)
    }

    public func open(_ id: String) { coordinator.openCertificate(id) }
    public func startLearning() { coordinator.openLearn() }
}
