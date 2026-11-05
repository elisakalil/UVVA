import Foundation
import Combine

@MainActor
public final class MapViewModel: MapViewModelProtocol {
    @Published public private(set) var uiModel = MapScreenUIModel()
    private var subscription: AnyCancellable?
    var selectedSnapshot: Int? { didSet { present(state.content) } }
    private let state: YouState
    private let coordinator: any YouCoordinatorProtocol
    private let now: () -> Date
    private let calendar: Calendar

    init(state: YouState, coordinator: any YouCoordinatorProtocol, now: @escaping () -> Date, calendar: Calendar) {
        self.state = state
        self.coordinator = coordinator
        self.now = now
        self.calendar = calendar
        subscription = state.$content.sink { [weak self] content in self?.present(content) }
    }

    public func selectSnapshot(_ index: Int) { selectedSnapshot = index }
    public func redoMap() { coordinator.redoMap() }

    private func present(_ content: YouContent) {
        let link = content.profile?.inviteLink.absoluteString ?? "uvva.app"
        uiModel = MapScreenUIModel(
            content: MapPresentationBuilder().build(from: content, selectedSnapshot: selectedSnapshot,
                                                     now: now(), calendar: calendar),
            name: content.profile?.firstName ?? "",
            shareMessage: String(localized: "This is my wine palate. Map yours on UVVA and we'll find the perfect wine to drink together. \(link)", bundle: .module)
        )
    }
}
