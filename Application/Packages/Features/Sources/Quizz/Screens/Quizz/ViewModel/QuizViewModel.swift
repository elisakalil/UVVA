import Core
import Foundation
import Match
import Combine

@MainActor
public final class QuizViewModel: QuizViewModelProtocol {
    @Published public private(set) var uiModel = QuizUIModel()
    private(set) var flow = QuizFlow() { didSet { refresh() } }
    private(set) var bank: QuizQuestionBank? { didSet { refresh() } }
    private(set) var isSharing = false { didSet { refresh() } }
    private(set) var isSaving = false { didSet { refresh() } }
    private(set) var failedToSave = false { didSet { refresh() } }

    private let entry: QuizEntry
    private let firstName: String?
    private let loadQuestionsUseCase: any LoadQuizQuestionsUseCaseProtocol
    private let saveMapUseCase: any SaveQuizMapUseCaseProtocol
    private let coordinator: any QuizCoordinatorProtocol

    init(entry: QuizEntry, firstName: String?, loadQuestionsUseCase: any LoadQuizQuestionsUseCaseProtocol,
         saveMapUseCase: any SaveQuizMapUseCaseProtocol, coordinator: any QuizCoordinatorProtocol) {
        self.entry = entry
        self.firstName = firstName
        self.loadQuestionsUseCase = loadQuestionsUseCase
        self.saveMapUseCase = saveMapUseCase
        self.coordinator = coordinator
        refresh()
    }

    func load() async {
        try? await prepare()
    }
    
    public func prepare() async throws {
        guard bank == nil else { return }

        let loaded = try await loadQuestionsUseCase.execute()
        try Task.checkCancellation()
        bank = loaded
    }

    public func start() { flow.start() }
    public func select(_ position: Int) { flow.select(position) }
    public func changeQuestion() { flow.changeQuestion() }
    public func next() { flow.next() }
    public func back() { flow.back() }
    public func readAgain() { flow.readAgain() }

    public func keep() async {
        guard let map = flow.map, !isSaving else { return }
        isSaving = true
        failedToSave = false
        do {
            try await saveMapUseCase.execute(map)
            isSharing = true
        } catch {
            failedToSave = true
        }
        isSaving = false
    }

    public func finish() { coordinator.finish() }
    public func leave() { coordinator.leave() }

    var screen: QuizScreen {
        let builder = QuizPresentationBuilder(entry: entry, firstName: firstName, flow: flow,
                                               isSaving: isSaving, failedToSave: failedToSave)
        if isSharing, let map = flow.map { return .share(builder.shareModel(map)) }
        switch flow.step {
        case .intro: return .intro(builder.introModel)
        case let .reading(index):
            guard let bank else { return .loading }
            return .reading(builder.readingModel(index, bank: bank))
        case .result:
            guard let map = flow.map else { return .loading }
            return .result(builder.resultModel(map))
        }
    }

    private func refresh() {
        uiModel = QuizUIModel(screen: screen, isReady: bank != nil, isSaving: isSaving,
                              failedToSave: failedToSave, isSharing: isSharing)
    }
}
