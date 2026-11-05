import Combine
import Core

@MainActor
protocol NameViewModelProtocol: ObservableObject {
    var uiModel: NameUIModel { get }
    func updateName(_ name: String)
    func back()
    func continueFromName()
}
