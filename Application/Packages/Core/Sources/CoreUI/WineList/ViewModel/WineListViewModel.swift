import Combine
import Core
import Foundation
import Match
import OSLog

/// The wine list (WINELIST.md): the pages read by the camera, "What's on the table?", the wines to order, best first,
/// and the line to say to the waiter.
@MainActor
public final class WineListViewModel: WineListViewModelProtocol, Identifiable {
    @Published public private(set) var uiModel = WineListUIModel()
    public nonisolated let id = UUID()

    private var state = WineListState() { didSet { refresh() } }
    private let prepareCamera: any PrepareCameraUseCaseProtocol
    private let readWineList: any ReadWineListUseCaseProtocol
    private let maps: (any PalateMapRepository)?
    private let friends: (any FriendsRepository)?
    private let recipes: (any CatalogRepository)?
    /// The wine ordered goes to a new note, on paper (WINELIST-R08).
    private let onAddToCellar: (Wine) -> Void
    private let logger = Logger(subsystem: "app.uvva", category: "winelist")

    init(prepareCamera: any PrepareCameraUseCaseProtocol, readWineList: any ReadWineListUseCaseProtocol,
         maps: (any PalateMapRepository)? = nil, friends: (any FriendsRepository)? = nil,
         recipes: (any CatalogRepository)? = nil, onAddToCellar: @escaping (Wine) -> Void = { _ in }) {
        self.prepareCamera = prepareCamera
        self.readWineList = readWineList
        self.maps = maps
        self.friends = friends
        self.recipes = recipes
        self.onAddToCellar = onAddToCellar
        refresh()
    }

    public convenience init(maps: any PalateMapRepository, friends: any FriendsRepository,
                            recipes: any CatalogRepository, labelCatalog: any LabelCatalogRepository,
                            reader: any WineListReading, camera: any CameraAuthorizing,
                            now: @escaping () -> Date = Date.init,
                            onAddToCellar: @escaping (Wine) -> Void) {
        self.init(prepareCamera: PrepareCameraUseCase(camera: camera),
                  readWineList: ReadWineListUseCase(reader: reader, catalog: LabelCatalogCache(catalog: labelCatalog),
                                                    now: now),
                  maps: maps, friends: friends, recipes: recipes, onAddToCellar: onAddToCellar)
    }

    public func start() async {
        if state.step == .checkingCamera {
            switch await prepareCamera.execute() {
            case .authorized: state.step = .capture
            case .denied: state.step = .cameraDenied
            case .notDetermined: break
            }
        }
        guard state.palate == nil else { return }
        let palate = try? await maps?.currentMap()
        let friends = (try? await friends?.friends()) ?? []
        let recipes = (try? await recipes?.recipes()) ?? []
        state.palate = palate
        // The friends added last first, as the Friends tab lists them.
        state.friends = friends.sorted { $0.addedAt > $1.addedAt }
        state.recipes = recipes
    }

    public func capture(_ photo: Data) async {
        guard state.step == .capture, !state.isReading else { return }
        state.isReading = true
        state.readingPhoto = photo
        state.pageMessage = nil
        defer {
            state.isReading = false
            state.readingPhoto = nil
        }
        do {
            let page = try await readWineList.execute(photo)
            let before = state.wines.count
            state.add(page.wines)
            state.currency = state.currency ?? page.currency
            state.pagesRead += 1
            if state.wines.count == before { state.pageMessage = uiModel.resources.noWinesText }
        } catch {
            logger.error("Wine list not read: \(error.localizedDescription, privacy: .public)")
            state.pageMessage = uiModel.resources.readFailedText
        }
    }

    public func useList() {
        guard state.step == .capture, !state.wines.isEmpty, !state.isReading else { return }
        state.step = .questions
    }

    public func back() {
        switch state.step {
        case .questions: state.step = .capture
        case .results: state.step = .questions
        case .ask: state.step = .results
        default: break
        }
    }

    public func toggleDish(_ id: String) {
        guard let dish = MenuDish(rawValue: id) else { return }
        if state.dishes.contains(dish) { state.dishes.remove(dish) } else { state.dishes.insert(dish) }
    }

    public func chooseBudget(_ id: String) { state.budget = Double(id) }

    public func togglePerson(_ id: String) {
        guard state.friends.contains(where: { $0.id == id }) else { return }
        if state.people.contains(id) { state.people.remove(id) } else { state.people.insert(id) }
    }

    public func showPicks() {
        guard state.step == .questions else { return }
        state.picks = WineListRanking.rank(state.wines, palates: state.palates, dishes: state.dishes,
                                           recipes: state.recipes, budget: state.budget)
        state.askedID = nil
        state.step = .results
    }

    public func ask(_ id: String) {
        guard state.step == .results, state.picks.contains(where: { $0.id == id }) else { return }
        state.askedID = id
        state.step = .ask
    }

    public func chooseLanguage(_ language: String) {
        guard let language = WineListLanguage(rawValue: language) else { return }
        state.language = language
    }

    public func addToCellar() {
        guard state.step == .ask, let pick = state.asked else { return }
        onAddToCellar(pick.wine.wine)
    }

    private func refresh() {
        var model = uiModel
        WineListPresentationBuilder(state: state, resources: model.resources).build(into: &model)
        uiModel = model
    }
}
