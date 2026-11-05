import Core
import Foundation
import Combine

@MainActor
public final class HomeViewModel: HomeViewModelProtocol {
    @Published public private(set) var uiModel = HomeUIModel()

    private var loadTask: Task<Void, Error>?

    private let loadHomeUseCase: any LoadHomeUseCaseProtocol
    private let addWineToCellarUseCase: any AddWineToCellarUseCaseProtocol
    private let coordinator: any HomeCoordinatorProtocol
    private let now: () -> Date
    private let calendar: Calendar

    init(
        loadHomeUseCase: any LoadHomeUseCaseProtocol,
        addWineToCellarUseCase: any AddWineToCellarUseCaseProtocol,
        coordinator: any HomeCoordinatorProtocol,
        now: @escaping () -> Date,
        calendar: Calendar
    ) {
        self.loadHomeUseCase = loadHomeUseCase
        self.addWineToCellarUseCase = addWineToCellarUseCase
        self.coordinator = coordinator
        self.now = now
        self.calendar = calendar
    }

    public func loadIfNeeded() async {
        guard uiModel.content == nil else { return }
        await load()
    }

    public func load() async {
        try? await prepare()
    }

    public func prepare() async throws {
        if let loadTask {
            try await loadTask.value
            try Task.checkCancellation()
            return
        }

        uiModel.isLoading = true
        let task = Task { try await self.readHome() }
        loadTask = task
        defer { loadTask = nil; uiModel.isLoading = false }

        try await task.value
        try Task.checkCancellation()
    }

    private func readHome() async throws {
        let content = try await loadHomeUseCase.execute()
        try Task.checkCancellation()
        present(content)
    }

    private func present(_ content: LoadedHomeContent) {
        let date = now()
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        let builder = HomeCardsBuilder(calendar: calendar, pickWordIndex: { day % $0 })

        uiModel = HomeUIModel(
            content: HomeContentUIModel(cards: builder.build(from: content.state, now: date),
                                         palateMap: content.state.palateMap),
            inviteLink: content.inviteLink, cellarWineKeys: content.cellarWineKeys, isLoading: false
        )
    }

    public func openCourse(_ id: String) { coordinator.openCourse(id) }

    public func openLearn(_ kind: CourseKind) { coordinator.openLearn(kind) }

    func addToCellar(_ wine: Wine) async {
        guard !uiModel.cellarWineKeys.contains(wine.id) else { return }
        guard (try? await addWineToCellarUseCase.execute(wine)) != nil else { return }
        uiModel.cellarWineKeys.insert(wine.id)
    }

}
