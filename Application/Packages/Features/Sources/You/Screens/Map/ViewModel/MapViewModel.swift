import Foundation
import Combine

@MainActor
public final class MapViewModel: MapViewModelProtocol {
    @Published public private(set) var uiModel = MapScreenUIModel()
    private let coordinator: any YouCoordinatorProtocol

    init(content: YouContentModel, coordinator: any YouCoordinatorProtocol) {
        self.coordinator = coordinator
        present(content)
    }

    public func redoMap() { coordinator.redoMap() }

    func present(_ content: YouContentModel) {
        let link = content.profile?.inviteLink.absoluteString ?? "uvva.app"
        uiModel = MapScreenUIModel(
            content: MapPresentationBuilder().build(from: content),
            name: content.profile?.firstName ?? "",
            shareMessage: String(localized: "This is my wine palate. Map yours on UVVA and we'll find the perfect wine to drink together. \(link)", bundle: .module)
        )
    }
}
