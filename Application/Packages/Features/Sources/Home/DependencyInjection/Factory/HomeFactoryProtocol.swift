import Core

@MainActor
public protocol HomeFactoryProtocol {
    func makeViewModel(coordinator: any HomeCoordinatorProtocol) -> HomeViewModel
}
