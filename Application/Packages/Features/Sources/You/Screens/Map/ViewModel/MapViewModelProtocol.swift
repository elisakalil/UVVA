import Combine
import Core
import Foundation

@MainActor
public protocol MapViewModelProtocol: ObservableObject {
    var uiModel: MapScreenUIModel { get }
    func selectSnapshot(_ index: Int)
    func redoMap()
}
