import Core
import Foundation
import Match
import Combine

/// Owns the data shared by You screens and propagates persisted changes to their presentation.
@MainActor
public final class YouViewModel: YouViewModelProtocol {
    typealias Screens = (progress: ProgressViewModel, map: MapViewModel, settings: SettingsViewModel)
    @Published public private(set) var uiModel = YouUIModel()
    private(set) var contentModel = YouContentModel() { didSet { present() } }
    private let loadYouUseCase: any LoadYouUseCaseProtocol
    private let makeScreens: (YouViewModel) -> Screens
    private lazy var screens = makeScreens(self)

    public var progress: ProgressViewModel { screens.progress }
    public var map: MapViewModel { screens.map }
    public var settings: SettingsViewModel { screens.settings }
    public var tab: YouTab {
        get { uiModel.tab }
        set { selectTab(newValue) }
    }

    init(loadYouUseCase: any LoadYouUseCaseProtocol, makeScreens: @escaping (YouViewModel) -> Screens) {
        self.loadYouUseCase = loadYouUseCase
        self.makeScreens = makeScreens
    }

    public func load() async {
        contentModel = await loadYouUseCase.execute(previous: contentModel)
        map.selectedSnapshot = nil
    }

    func profileSaved(_ profile: Profile) { contentModel.profile = profile }
    func reminderSaved(_ reminder: Reminder?) { contentModel.reminder = reminder }
    public func selectTab(_ tab: YouTab) { uiModel.tab = tab }

    private func present() {
        let model = contentModel
        uiModel.header = YouHeaderUIModel(name: model.profile?.firstName ?? "",
                                          signature: model.map.map { MapReading(map: $0).signature } ?? "",
                                          photo: model.profile?.photo)
        progress.present(model)
        map.present(model)
        settings.present(model)
    }
}
