import Combine
import Core
import Foundation

@MainActor
public protocol ProgressViewModelProtocol: ObservableObject {
    var uiModel: ProgressUIModel { get }
    func startCourse()
}
