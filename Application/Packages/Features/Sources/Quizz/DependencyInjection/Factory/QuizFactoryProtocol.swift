import Core

@MainActor
public protocol QuizFactoryProtocol {
    func makeViewModel(entry: QuizEntry, firstName: String?, coordinator: any QuizCoordinatorProtocol) -> QuizViewModel
}
