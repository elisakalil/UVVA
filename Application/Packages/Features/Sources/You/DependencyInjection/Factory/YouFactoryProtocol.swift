@MainActor
public protocol YouFactoryProtocol {
    func makeViewModel(coordinator: any YouCoordinatorProtocol) -> YouViewModel
}
