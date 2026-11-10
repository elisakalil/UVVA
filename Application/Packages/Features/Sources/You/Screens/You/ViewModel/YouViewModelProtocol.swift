import Combine
import Core
import Foundation

@MainActor
public protocol YouViewModelProtocol: ObservableObject {
    var uiModel: YouUIModel { get }
    associatedtype ProgressModel: ProgressViewModelProtocol
    var progress: ProgressModel { get }
    associatedtype MapModel: MapViewModelProtocol
    var map: MapModel { get }
    associatedtype SettingsModel: SettingsViewModelProtocol
    var settings: SettingsModel { get }
    func load() async
    func selectTab(_ tab: YouTab)
    /// The page reached "Over time", or left before it could (YOU-R03).
    func mapHistoryShown()
}
