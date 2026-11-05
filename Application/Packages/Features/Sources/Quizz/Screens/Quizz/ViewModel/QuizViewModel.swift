import Core
import Foundation
import Match
import Observation

@MainActor @Observable
public final class QuizViewModel {
    private(set) var flow = QuizFlow()
    private(set) var bank: QuizQuestionBank?
    private(set) var isSharing = false
    private(set) var isSaving = false
    private(set) var failedToSave = false

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

    func start() { flow.start() }
    func select(_ position: Int) { flow.select(position) }
    func changeQuestion() { flow.changeQuestion() }
    func next() { flow.next() }
    func back() { flow.back() }
    func readAgain() { flow.readAgain() }

    func keep() async {
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

    func finish() { coordinator.finish() }
    func leave() { coordinator.leave() }

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

}
