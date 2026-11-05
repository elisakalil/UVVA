#if DEBUG
import Combine
import Core

@MainActor
final class MockQuizViewModel: QuizViewModelProtocol {
    @Published var uiModel: QuizUIModel
    init() {
        let builder = QuizPresentationBuilder(entry: .firstMap, firstName: "Elisa", flow: QuizFlow(),
                                               isSaving: false, failedToSave: false)
        uiModel = QuizUIModel(screen: .intro(builder.introModel), isReady: true)
    }
    func start() {}
    func select(_ position: Int) {}
    func changeQuestion() {}
    func next() {}
    func back() {}
    func readAgain() {}
    func keep() async {}
    func finish() {}
    func leave() {}
}
#endif
