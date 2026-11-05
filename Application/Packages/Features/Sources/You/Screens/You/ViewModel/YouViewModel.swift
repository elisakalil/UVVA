import Core
import Foundation
import Match
import Combine

/// Owns the You tab shell; screen state and operations belong to their respective ViewModels.
@MainActor
public final class YouViewModel: YouViewModelProtocol {
    @Published public private(set) var uiModel = YouUIModel()
    public var tab: YouTab {
        get { uiModel.tab }
        set { selectTab(newValue) }
    }
    private var subscription: AnyCancellable?
    public let progress: ProgressViewModel
    public let map: MapViewModel
    public let settings: SettingsViewModel
    private let state: YouState
    private let loadYouUseCase: any LoadYouUseCaseProtocol

    init(state: YouState, loadYouUseCase: any LoadYouUseCaseProtocol,
         progress: ProgressViewModel, map: MapViewModel, settings: SettingsViewModel) {
        self.state = state
        self.loadYouUseCase = loadYouUseCase
        self.progress = progress
        self.map = map
        self.settings = settings
        subscription = state.$content.sink { [weak self] content in
            self?.uiModel.header = YouHeaderUIModel(name: content.profile?.firstName ?? "",
                                                    signature: content.map.map { MapReading(map: $0).signature } ?? "",
                                                    photo: content.profile?.photo)
        }
    }

    public func load() async {
        state.content = await loadYouUseCase.execute(previous: state.content)
        map.selectedSnapshot = nil
    }

    public func selectTab(_ tab: YouTab) { uiModel.tab = tab }
}
