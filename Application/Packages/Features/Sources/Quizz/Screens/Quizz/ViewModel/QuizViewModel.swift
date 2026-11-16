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
    /// The map "Draw the map" made (QUIZ-R04a to R04c): the one shown, shared and kept. Nil while it is drawn.
    private(set) var drawnMap: PalateMap? { didSet { refresh() } }
    private var drawing: Task<Void, Never>?

    private let entry: QuizEntry
    private let firstName: String?
    private let loadQuestionsUseCase: any LoadQuizQuestionsUseCaseProtocol
    private let drawMapUseCase: any DrawQuizMapUseCaseProtocol
    private let saveMapUseCase: any SaveQuizMapUseCaseProtocol
    private let coordinator: any QuizCoordinatorProtocol

    init(entry: QuizEntry, firstName: String?, loadQuestionsUseCase: any LoadQuizQuestionsUseCaseProtocol,
         drawMapUseCase: any DrawQuizMapUseCaseProtocol, saveMapUseCase: any SaveQuizMapUseCaseProtocol,
         coordinator: any QuizCoordinatorProtocol) {
        self.entry = entry
        self.firstName = firstName
        self.loadQuestionsUseCase = loadQuestionsUseCase
        self.drawMapUseCase = drawMapUseCase
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
    public func next() {
        flow.next()
        if flow.step == .result { draw() }
    }

    public func back() { flow.back() }

    public func readAgain() {
        drawing?.cancel()
        drawnMap = nil
        flow.readAgain()
    }

    /// QUIZ-R04a to R04c: the answers settled among real wines. Drawn again whenever the map is reached, since the
    /// answers may have changed on the way back.
    private func draw() {
        drawing?.cancel()
        drawnMap = nil
        let answers = flow.answers
        drawing = Task { [weak self, drawMapUseCase] in
            let map = await drawMapUseCase.execute(answers)
            guard !Task.isCancelled, let self, self.flow.answers == answers else { return }
            self.drawnMap = map
        }
    }

    /// Waits for the map being drawn, if any.
    func waitForMap() async { await drawing?.value }

    public func keep() async {
        await waitForMap()
        guard let map = drawnMap, flow.isComplete, !isSaving else { return }
        isSaving = true
        failedToSave = false
        do {
            try await saveMapUseCase.execute(map, answers: flow.answers)
            isSharing = true
        } catch {
            failedToSave = true
        }
        isSaving = false
    }

    public func finish() { coordinator.finish() }
    public func leave() { coordinator.leave() }

    var screen: QuizViewState {
        let builder = QuizPresentationBuilder(entry: entry, firstName: firstName, flow: flow,
                                               isSaving: isSaving, failedToSave: failedToSave)
        if isSharing, let map = drawnMap { return .share(builder.shareModel(map)) }
        switch flow.step {
        case .intro: return .intro(builder.introModel)
        case let .reading(index):
            guard let bank else { return .loading }
            return .reading(builder.readingModel(index, bank: bank))
        case .result:
            guard let map = drawnMap else { return .loading }
            return .result(builder.resultModel(map))
        }
    }

    private func refresh() {
        uiModel = QuizUIModel(screen: screen, isReady: bank != nil, isSaving: isSaving,
                              failedToSave: failedToSave, isSharing: isSharing)
    }
}
