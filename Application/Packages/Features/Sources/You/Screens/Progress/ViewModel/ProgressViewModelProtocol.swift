import Combine
import Core
import Foundation

@MainActor
public protocol ProgressViewModelProtocol: ObservableObject {
    var uiModel: ProgressUIModel { get }
    func startCourse()
    /// A wine from a place on the map (YOU-R07a): its note in the Cellar.
    func openWine(_ id: String)
}
