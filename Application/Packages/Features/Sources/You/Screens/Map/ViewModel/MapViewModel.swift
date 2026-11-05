import Foundation
import Observation

@MainActor @Observable
final class MapViewModel {
    var selectedSnapshot: Int?
    private let state: YouState
    private let coordinator: any YouCoordinatorProtocol
    private let now: () -> Date
    private let calendar: Calendar

    init(state: YouState, coordinator: any YouCoordinatorProtocol, now: @escaping () -> Date, calendar: Calendar) {
        self.state = state
        self.coordinator = coordinator
        self.now = now
        self.calendar = calendar
    }

    var model: MapUIModel? {
        MapPresentationBuilder().build(from: state.content, selectedSnapshot: selectedSnapshot, now: now(), calendar: calendar)
    }

    var name: String { state.content.profile?.firstName ?? "" }
    func selectSnapshot(_ index: Int) { selectedSnapshot = index }
    func redoMap() { coordinator.redoMap() }

    var shareMessage: String {
        let link = state.content.profile?.inviteLink.absoluteString ?? "uvva.app"
        return String(localized: "This is my wine palate. Map yours on UVVA and we'll find the perfect wine to drink together. \(link)", bundle: .module)
    }

}
