import Foundation
import Combine

@MainActor
public final class MapViewModel: MapViewModelProtocol {
    @Published public private(set) var uiModel = MapScreenUIModel()
    var selectedSnapshot: Int? { didSet { present(readModel()) } }
    private let readModel: () -> YouContentModel
    private let coordinator: any YouCoordinatorProtocol
    private let now: () -> Date
    private let calendar: Calendar

    init(readModel: @escaping () -> YouContentModel, coordinator: any YouCoordinatorProtocol, now: @escaping () -> Date, calendar: Calendar) {
        self.readModel = readModel
        self.coordinator = coordinator
        self.now = now
        self.calendar = calendar
        present(readModel())
    }

    public func selectSnapshot(_ index: Int) { selectedSnapshot = index }
    public func redoMap() { coordinator.redoMap() }

    func present(_ content: YouContentModel) {
        let link = content.profile?.inviteLink.absoluteString ?? "uvva.app"
        uiModel = MapScreenUIModel(
            content: MapPresentationBuilder().build(from: content, selectedSnapshot: selectedSnapshot,
                                                     now: now(), calendar: calendar),
            name: content.profile?.firstName ?? "",
            shareMessage: String(localized: "This is my wine palate. Map yours on UVVA and we'll find the perfect wine to drink together. \(link)", bundle: .module)
        )
    }
}
