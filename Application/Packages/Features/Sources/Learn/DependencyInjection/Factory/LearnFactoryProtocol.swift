@MainActor
public protocol LearnFactoryProtocol {
    func makeViewModel(onProgressChange: @escaping () -> Void) -> LearnViewModel
}
