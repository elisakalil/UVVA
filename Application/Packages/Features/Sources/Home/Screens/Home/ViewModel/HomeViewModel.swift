import Core
import Foundation
import Observation

@MainActor @Observable
public final class HomeViewModel {
    private(set) var model: HomeUIModel?
    private(set) var inviteLink: URL?
    private(set) var cellarWineKeys: Set<String> = []
    
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
        guard model == nil else { return }
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

        let task = Task { try await self.readHome() }
        loadTask = task
        defer { loadTask = nil }

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

        inviteLink = content.inviteLink
        cellarWineKeys = content.cellarWineKeys
        model = HomeUIModel(
            cards: builder.build(from: content.state, now: date),
            palateMap: content.state.palateMap
        )
    }

    func openCourse(_ id: String) { coordinator.openCourse(id) }

    func openLearn(_ kind: CourseKind) { coordinator.openLearn(kind) }

    func addToCellar(_ wine: Wine) async {
        guard !cellarWineKeys.contains(wine.id) else { return }
        guard (try? await addWineToCellarUseCase.execute(wine)) != nil else { return }
        cellarWineKeys.insert(wine.id)
    }

    var inviteMessage: String {
        String(localized: "Map your taste in wine with me on UVVA.", bundle: .module)
    }
}
