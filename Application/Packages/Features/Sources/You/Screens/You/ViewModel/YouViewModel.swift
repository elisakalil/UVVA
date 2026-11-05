import Core
import Foundation
import Match
import Observation

/// Owns the You tab shell; screen state and operations belong to their respective ViewModels.
@MainActor @Observable
public final class YouViewModel {
    public var tab: YouTab = .progress
    let progress: ProgressViewModel
    let map: MapViewModel
    let settings: SettingsViewModel
    private let state: YouState
    private let loadYouUseCase: any LoadYouUseCaseProtocol

    init(state: YouState, loadYouUseCase: any LoadYouUseCaseProtocol,
         progress: ProgressViewModel, map: MapViewModel, settings: SettingsViewModel) {
        self.state = state
        self.loadYouUseCase = loadYouUseCase
        self.progress = progress
        self.map = map
        self.settings = settings
    }

    public func load() async {
        state.content = await loadYouUseCase.execute(previous: state.content)
        map.selectedSnapshot = nil
    }

    var header: YouHeaderUIModel {
        let profile = state.content.profile
        return YouHeaderUIModel(name: profile?.firstName ?? "",
                                signature: state.content.map.map { MapReading(map: $0).signature } ?? "",
                                photo: profile?.photo)
    }
}
