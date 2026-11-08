import Core
import Foundation
import Combine
import Match

@MainActor
public final class HomeViewModel: HomeViewModelProtocol {
    @Published public private(set) var uiModel = HomeUIModel()

    private var presentedDay: Date?
    private var loadTask: Task<Void, Error>?
    private var noticeTask: Task<Void, Never>?

    private let loadHomeUseCase: any LoadHomeUseCaseProtocol
    private let addWineToCellarUseCase: any AddWineToCellarUseCaseProtocol
    private let rateWineUseCase: any RateWineUseCaseProtocol
    private let coordinator: any HomeCoordinatorProtocol
    private let now: () -> Date
    private let calendar: Calendar
    /// How long a notice stays (HOME-R24); injected so tests need not wait for it.
    private let noticeDuration: Duration

    init(
        loadHomeUseCase: any LoadHomeUseCaseProtocol,
        addWineToCellarUseCase: any AddWineToCellarUseCaseProtocol,
        rateWineUseCase: any RateWineUseCaseProtocol,
        coordinator: any HomeCoordinatorProtocol,
        now: @escaping () -> Date,
        calendar: Calendar,
        noticeDuration: Duration = .seconds(3)
    ) {
        self.loadHomeUseCase = loadHomeUseCase
        self.addWineToCellarUseCase = addWineToCellarUseCase
        self.rateWineUseCase = rateWineUseCase
        self.coordinator = coordinator
        self.now = now
        self.calendar = calendar
        self.noticeDuration = noticeDuration
    }

    public func loadIfNeeded() async {
        guard uiModel.content == nil || presentedDay.map({ !calendar.isDate($0, inSameDayAs: now()) }) == true else { return }
        await load()
    }

    public func load() async {
        // A progress change requires a fresh read, even if an older Home snapshot is in flight.
        if let pending = loadTask { try? await pending.value }
        try? await prepare()
    }

    public func prepare() async throws {
        if let loadTask {
            try await loadTask.value
            try Task.checkCancellation()
            return
        }

        uiModel.isLoading = true
        let task = Task {
            defer { self.loadTask = nil; self.uiModel.isLoading = false }
            try await self.readHome()
        }
        loadTask = task

        try await task.value
        try Task.checkCancellation()
    }

    private func readHome() async throws {
        let content = try await loadHomeUseCase.execute()
        try Task.checkCancellation()
        present(content)
    }

    private func present(_ content: HomeLoadResultModel) {
        let date = now()
        presentedDay = date
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        let builder = HomeCardsBuilder(calendar: calendar, pickWordIndex: { day % $0 })

        let notice = uiModel.notice
        uiModel = HomeUIModel(
            content: HomeContentUIModel(cards: builder.build(from: content.model, now: date),
                                         glossary: content.model.glossary, firstName: content.model.firstName, palateMap: content.model.palateMap),
            inviteLink: content.inviteLink, cellarWineKeys: content.cellarWineKeys, isLoading: false, notice: notice
        )
    }

    public func openCourse(_ id: String) { coordinator.openCourse(id) }

    public func openLesson(_ suggestion: HomeLessonSuggestion) { coordinator.openLesson(suggestion) }

    public func openLearn(_ kind: CourseKind) { coordinator.openLearn(kind) }

    public func scan() { coordinator.scan() }
    public func openFriends() { coordinator.openFriends() }
    public func openLastTable() { coordinator.openLastTable() }

    public func addToCellar(_ wine: Wine) async {
        guard !uiModel.cellarWineKeys.contains(wine.id) else { return }
        guard (try? await addWineToCellarUseCase.execute(wine)) != nil else { return }
        uiModel.cellarWineKeys.insert(wine.id)
        show(uiModel.resources.savedToCellarNotice(wine))
    }

    /// HOME-R24: the map moves and the Home is built again on it, so the rated wine leaves the list (HOME-R23)
    /// and the others follow the new map; then the notice tells which axes moved.
    public func rate(_ wine: Wine, verdict: Verdict, addToCellar: Bool) async {
        guard let changes = try? await rateWineUseCase.execute(wine, verdict: verdict, addToCellar: addToCellar) else { return }
        await load()
        show(uiModel.resources.mapUpdatedNotice(changes.map { ($0.axis, $0.wentUp) }, savedToCellar: addToCellar))
    }

    private func show(_ notice: String) {
        noticeTask?.cancel()
        uiModel.notice = notice
        let duration = noticeDuration
        noticeTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            self?.uiModel.notice = nil
        }
    }

}
