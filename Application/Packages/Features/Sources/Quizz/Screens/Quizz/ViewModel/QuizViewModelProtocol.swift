import Combine

@MainActor
public protocol QuizViewModelProtocol: ObservableObject {
    var uiModel: QuizUIModel { get }
    func start()
    func select(_ position: Int)
    func changeQuestion()
    func next()
    func back()
    func readAgain()
    func keep() async
    func finish()
    func leave()
}
