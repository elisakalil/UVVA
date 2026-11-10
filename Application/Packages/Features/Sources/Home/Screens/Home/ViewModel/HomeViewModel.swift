import Core
import Foundation
import Combine
import Match

@MainActor
public final class HomeViewModel: HomeViewModelProtocol {
    @Published public private(set) var uiModel = HomeUIModel()

    private var presentedDay: Date?
    /// What the cards on screen were built from, kept so the cards that follow the map can be read again alone.
    private var loaded: HomeLoadResultModel?
    /// The map may have moved outside the Home (HOME-R10c); checked the next time the Home is shown.
    private var matchesMayBeStale = false
    private var loadTask: Task<Void, Error>?
    private var noticeTask: Task<Void, Never>?

    private let loadHomeUseCase: any LoadHomeUseCaseProtocol
    private let loadPalateStateUseCase: any LoadPalateStateUseCaseProtocol
    private let rankWinesUseCase: any RankWinesUseCaseProtocol
    private let addWineToCellarUseCase: any AddWineToCellarUseCaseProtocol
    private let rateWineUseCase: any RateWineUseCaseProtocol
    private let coordinator: any HomeCoordinatorProtocol
    private let now: () -> Date
    private let calendar: Calendar
    /// How long a notice stays (HOME-R24); injected so tests need not wait for it.
    private let noticeDuration: Duration
    /// The least time the curtain of HOME-R10c stays, so it is seen running and not as a flicker; injected so tests
    /// need not wait for it.
    private let curtainDuration: Duration

    init(
        loadHomeUseCase: any LoadHomeUseCaseProtocol,
        loadPalateStateUseCase: any LoadPalateStateUseCaseProtocol,
        rankWinesUseCase: any RankWinesUseCaseProtocol,
        addWineToCellarUseCase: any AddWineToCellarUseCaseProtocol,
        rateWineUseCase: any RateWineUseCaseProtocol,
        coordinator: any HomeCoordinatorProtocol,
        now: @escaping () -> Date,
        calendar: Calendar,
        noticeDuration: Duration = .seconds(3),
        curtainDuration: Duration = .milliseconds(1800)
    ) {
        self.loadHomeUseCase = loadHomeUseCase
        self.loadPalateStateUseCase = loadPalateStateUseCase
        self.rankWinesUseCase = rankWinesUseCase
        self.curtainDuration = curtainDuration
        self.addWineToCellarUseCase = addWineToCellarUseCase
        self.rateWineUseCase = rateWineUseCase
        self.coordinator = coordinator
        self.now = now
        self.calendar = calendar
        self.noticeDuration = noticeDuration
    }

    public func loadIfNeeded() async {
        guard uiModel.content == nil || presentedDay.map({ !calendar.isDate($0, inSameDayAs: now()) }) == true else {
            if matchesMayBeStale { await refreshMatches() }
            return
        }
        await load()
    }

    /// HOME-R10c: the map may have moved outside the Home (a note edited or deleted in the Cellar). Nothing is read
    /// now: the next time the Home is shown (`loadIfNeeded`), the cards that follow the map are read again, once,
    /// however many notes changed meanwhile.
    public func palateChanged() {
        matchesMayBeStale = true
    }

    /// HOME-R10c: reads again only what follows the map (the Hero, "Wines for your palate" and the map the other
    /// cards are drawn on), under the curtain. The rest of the Home is not read. If nothing those cards follow has
    /// changed (a note that only changed its text), there is no curtain and the catalog is not ranked.
    public func refreshMatches() async {
        // A read in flight may have started before the change: wait for it, then read on the new map.
        if let pending = loadTask { try? await pending.value }
        guard loaded != nil else { return await load() }
        // Another caller got here first; its read is as fresh as this one would be.
        if let loadTask { try? await loadTask.value; return }

        let task = Task {
            defer { self.loadTask = nil; self.uiModel.isRefreshingMatches = false }
            try await self.readMatches()
        }
        loadTask = task
        try? await task.value
    }

    private func readMatches() async throws {
        guard var result = loaded else { return }
        matchesMayBeStale = false
        let state = try await loadPalateStateUseCase.execute()
        try Task.checkCancellation()

        result.cellarWineKeys = state.cellarWineKeys
        let mapMoved = state.palateMap != result.model.palateMap
        guard mapMoved || state.ratedWineIDs != result.model.ratedWineIDs || state.lastRating != result.model.lastRating else {
            loaded = result
            uiModel.cellarWineKeys = state.cellarWineKeys
            return
        }

        uiModel.isRefreshingMatches = true
        let clock = ContinuousClock()
        let raised = clock.now

        result.model.palateMap = state.palateMap
        result.model.ratedWineIDs = state.ratedWineIDs
        result.model.lastRating = state.lastRating
        // The ranking only depends on the map: ratings that left it where it was keep the one already read.
        if mapMoved { result.model.catalog = try await rankWinesUseCase.execute(for: state.palateMap) }
        try Task.checkCancellation()
        let cards = await buildCards(from: result.model, at: presentedDay ?? now())

        let rest = curtainDuration - (clock.now - raised)
        if rest > .zero { try await Task.sleep(for: rest) }
        try Task.checkCancellation()
        present(result, cards: cards, at: presentedDay ?? now())
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
        // A full read covers the map too; a change that arrives while it runs is checked on the next visit.
        matchesMayBeStale = false
        let content = try await loadHomeUseCase.execute()
        try Task.checkCancellation()

        let date = now()
        let cards = await buildCards(from: content.model, at: date)
        try Task.checkCancellation()
        present(content, cards: cards, at: date)
    }

    /// The cards read the whole catalog (the top of the match list, a wine per axis), so they are built away from the
    /// main actor, which only publishes them. Only Sendable values cross into the background task.
    private func buildCards(from model: HomeContentModel, at date: Date) async -> [HomeCardModel] {
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        let builder = HomeCardsBuilder(calendar: calendar, pickWordIndex: { day % $0 })
        return await Task.detached(priority: .userInitiated) {
            builder.build(from: model, now: date)
        }.value
    }

    /// One assignment: the new cards and the end of any loading reach the views together.
    private func present(_ content: HomeLoadResultModel, cards: [HomeCardModel], at date: Date) {
        presentedDay = date
        loaded = content
        let notice = uiModel.notice
        uiModel = HomeUIModel(
            content: HomeContentUIModel(cards: cards,
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
    public func openMapHistory() { coordinator.openMapHistory() }

    public func addToCellar(_ wine: Wine) async {
        guard !uiModel.cellarWineKeys.contains(wine.id) else { return }
        guard (try? await addWineToCellarUseCase.execute(wine)) != nil else { return }
        uiModel.cellarWineKeys.insert(wine.id)
        show(uiModel.resources.savedToCellarNotice(wine))
    }

    /// HOME-R24: the map moves and the notice tells which axes moved; what follows the map is read again on it
    /// (HOME-R10c), so the rated wine leaves the list (HOME-R23) and the Hero is the new top of the match (HOME-R07).
    public func rate(_ wine: Wine, verdict: Verdict, addToCellar: Bool) async {
        guard let changes = try? await rateWineUseCase.execute(wine, verdict: verdict, addToCellar: addToCellar) else { return }
        show(uiModel.resources.mapUpdatedNotice(changes.map { ($0.axis, $0.wentUp) }, savedToCellar: addToCellar))
        await refreshMatches()
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
